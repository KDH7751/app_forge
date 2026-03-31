// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Firebase Auth Repository
///
/// 역할:
/// - FirebaseAuth login/signup/logout/reset과 users 문서 upsert를 단일 성공 흐름으로 묶음.
///
/// 경계:
/// - UI/controller는 Firebase나 Firestore를 직접 알지 않음.
/// - users upsert 실패 시 rollback signOut은 repository 내부에서 닫음.
/// ===================================================================

import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_error.dart';
import '../domain/app_logger.dart';
import '../domain/auth_repository.dart';
import '../domain/result.dart';
import 'users_document_datasource.dart';

/// Firebase 기반 auth repository 구현.
class AuthRepositoryFirebase implements AuthRepository {
  AuthRepositoryFirebase({
    required FirebaseAuth firebaseAuth,
    required UsersDocumentDataSource usersDataSource,
    required AppLogger logger,
  }) : _firebaseAuth = firebaseAuth,
       _usersDataSource = usersDataSource,
       _logger = logger;

  final FirebaseAuth _firebaseAuth;
  final UsersDocumentDataSource _usersDataSource;
  final AppLogger _logger;

  /// 이메일/비밀번호 login + users upsert 수행.
  @override
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    _logger.info('auth.login.start');

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      final resolvedEmail = _resolveUserEmail(user);

      if (user == null || resolvedEmail == null) {
        _logger.warn('auth.login.invalid-user');
        await _safeRollbackSignOut();

        return const Result<void>.failure(AppError.unknown);
      }

      try {
        await _usersDataSource.upsertUser(uid: user.uid, email: resolvedEmail);
      } on FirebaseException catch (error, stackTrace) {
        _logger.error(
          'auth.login.users-upsert.failed',
          error: error,
          stackTrace: stackTrace,
        );
        await _safeRollbackSignOut();

        return Result<void>.failure(_mapFirestoreError(error));
      } catch (error, stackTrace) {
        _logger.error(
          'auth.login.users-upsert.failed.unknown',
          error: error,
          stackTrace: stackTrace,
        );
        await _safeRollbackSignOut();

        return const Result<void>.failure(AppError.unknown);
      }

      _logger.info('auth.login.success');

      return const Result<void>.success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      _logger.error(
        'auth.login.firebase-auth.failed',
        error: error,
        stackTrace: stackTrace,
      );

      return Result<void>.failure(_mapLoginError(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.login.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppError.unknown);
    }
  }

  /// 이메일/비밀번호 signup + users upsert 수행.
  @override
  Future<Result<void>> signup({
    required String email,
    required String password,
  }) async {
    _logger.info('auth.signup.start');

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      final resolvedEmail = _resolveUserEmail(user);

      if (user == null || resolvedEmail == null) {
        _logger.warn('auth.signup.invalid-user');
        await _safeRollbackSignOut();

        return const Result<void>.failure(AppError.unknown);
      }

      try {
        await _usersDataSource.upsertUser(uid: user.uid, email: resolvedEmail);
      } on FirebaseException catch (error, stackTrace) {
        _logger.error(
          'auth.signup.users-upsert.failed',
          error: error,
          stackTrace: stackTrace,
        );
        await _safeRollbackSignOut();

        return Result<void>.failure(_mapFirestoreError(error));
      } catch (error, stackTrace) {
        _logger.error(
          'auth.signup.users-upsert.failed.unknown',
          error: error,
          stackTrace: stackTrace,
        );
        await _safeRollbackSignOut();

        return const Result<void>.failure(AppError.unknown);
      }

      _logger.info('auth.signup.success');

      return const Result<void>.success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      _logger.error(
        'auth.signup.firebase-auth.failed',
        error: error,
        stackTrace: stackTrace,
      );

      return Result<void>.failure(_mapSignupError(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.signup.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppError.unknown);
    }
  }

  /// logout 수행.
  @override
  Future<Result<void>> logout() async {
    _logger.info('auth.logout.start');

    try {
      await _firebaseAuth.signOut();
      _logger.info('auth.logout.success');

      return const Result<void>.success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      _logger.error('auth.logout.failed', error: error, stackTrace: stackTrace);

      return const Result<void>.failure(AppError.unknown);
    } catch (error, stackTrace) {
      _logger.error(
        'auth.logout.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppError.unknown);
    }
  }

  /// 비밀번호 재설정 이메일 발송.
  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    _logger.info('auth.reset-password.start');

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.info('auth.reset-password.success');

      return const Result<void>.success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      _logger.error(
        'auth.reset-password.failed',
        error: error,
        stackTrace: stackTrace,
      );

      return Result<void>.failure(_mapResetError(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.reset-password.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppError.unknown);
    }
  }

  /// login submit validation.
  @override
  Result<void> validateLogin({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim();

    if (!_isValidEmail(normalizedEmail)) {
      return const Result<void>.failure(AppError.invalidEmail);
    }

    if (!_isValidPassword(password)) {
      return const Result<void>.failure(AppError.invalidPassword);
    }

    return const Result<void>.success(null);
  }

  /// signup submit validation.
  @override
  Result<void> validateSignup({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final emailValidation = validateReset(email: email);

    if (emailValidation is Failure<void>) {
      return emailValidation;
    }

    if (!_isValidPassword(password)) {
      return const Result<void>.failure(AppError.invalidPassword);
    }

    if (password != confirmPassword) {
      return const Result<void>.failure(AppError.passwordMismatch);
    }

    return const Result<void>.success(null);
  }

  /// reset submit validation.
  @override
  Result<void> validateReset({required String email}) {
    if (!_isValidEmail(email.trim())) {
      return const Result<void>.failure(AppError.invalidEmail);
    }

    return const Result<void>.success(null);
  }

  /// users upsert 실패 후 rollback signOut.
  Future<void> _safeRollbackSignOut() async {
    try {
      await _firebaseAuth.signOut();
      _logger.info('auth.login.rollback-signout.success');
    } catch (error, stackTrace) {
      _logger.error(
        'auth.login.rollback-signout.failed',
        error: error,
        stackTrace: stackTrace,
      );
      _logger.warn(
        'auth.login.rollback-signout.fallback: partial auth state may remain '
        'until the next auth refresh or explicit logout attempt',
      );
    }
  }

  /// Firebase user에서 repository가 허용하는 email만 추출.
  String? _resolveUserEmail(User? user) {
    final email = user?.email;

    if (email == null || email.isEmpty) {
      return null;
    }

    return email;
  }

  /// FirebaseAuthException -> login AppError 매핑.
  AppError _mapLoginError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AppError.userNotFound;
      case 'wrong-password':
        return AppError.wrongPassword;
      case 'invalid-email':
      case 'invalid-credential':
        return AppError.invalidEmail;
      case 'network-request-failed':
        return AppError.network;
      default:
        return AppError.unknown;
    }
  }

  /// FirebaseAuthException -> signup AppError 매핑.
  AppError _mapSignupError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return AppError.emailAlreadyInUse;
      case 'weak-password':
        return AppError.weakPassword;
      case 'invalid-email':
        return AppError.invalidEmail;
      case 'network-request-failed':
        return AppError.network;
      default:
        return AppError.unknown;
    }
  }

  /// FirebaseAuthException -> reset AppError 매핑.
  AppError _mapResetError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AppError.userNotFound;
      case 'invalid-email':
        return AppError.invalidEmail;
      case 'network-request-failed':
        return AppError.network;
      default:
        return AppError.unknown;
    }
  }

  /// Firestore 오류 -> AppError 매핑.
  AppError _mapFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'unavailable':
      case 'network-request-failed':
        return AppError.network;
      default:
        return AppError.unknown;
    }
  }

  /// 간단한 이메일 형식 검증.
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }

  /// 최소 비밀번호 규칙.
  bool _isValidPassword(String password) {
    return password.length >= 8;
  }
}
