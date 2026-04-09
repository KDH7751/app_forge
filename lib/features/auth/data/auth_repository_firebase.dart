// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Firebase Auth Repository
///
/// 역할:
/// - FirebaseAuth / Firestore 호출과 AppError 매핑을 auth action 결과로 닫음.
///
/// 경계:
/// - UI/controller는 Firebase나 Firestore를 직접 알지 않음.
/// - validation 규칙은 domain helper가 소유하고, 이 파일은 concrete 실행만 담당함.
/// ===================================================================

import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_error.dart';
import '../domain/app_logger.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_validation.dart';
import '../domain/change_password_input.dart';
import '../domain/delete_account_input.dart';
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
    return validateLoginInput(email: email, password: password);
  }

  /// signup submit validation.
  @override
  Result<void> validateSignup({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return validateSignupInput(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  /// reset submit validation.
  @override
  Result<void> validateReset({required String email}) {
    return validateResetInput(email: email);
  }

  /// change password submit validation.
  @override
  Result<void> validateChangePassword(ChangePasswordInput input) {
    return validateChangePasswordInput(input);
  }

  /// delete account submit validation.
  @override
  Result<void> validateDeleteAccount(DeleteAccountInput input) {
    return validateDeleteAccountInput(input);
  }

  /// reauthenticate 후 현재 사용자 비밀번호 변경 수행.
  @override
  Future<Result<void>> changePassword(ChangePasswordInput input) async {
    _logger.info('auth.change-password.start');

    final user = _firebaseAuth.currentUser;
    final email = _resolveUserEmail(user);

    if (user == null || email == null) {
      _logger.warn('auth.change-password.invalid-user');

      return const Result<void>.failure(AppError.unknown);
    }

    try {
      await _reauthenticate(
        user: user,
        email: email,
        currentPassword: input.currentPassword,
      );
      await user.updatePassword(input.newPassword);
      _logger.info('auth.change-password.success');

      return const Result<void>.success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      _logger.error(
        'auth.change-password.failed',
        error: error,
        stackTrace: stackTrace,
      );

      return Result<void>.failure(_mapChangePasswordError(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.change-password.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppError.unknown);
    }
  }

  /// reauthenticate 후 계정 삭제와 users 문서 삭제를 순서대로 수행.
  @override
  Future<Result<void>> deleteAccount(DeleteAccountInput input) async {
    _logger.info('auth.delete-account.start');

    final user = _firebaseAuth.currentUser;
    final email = _resolveUserEmail(user);

    if (user == null || email == null) {
      _logger.warn('auth.delete-account.invalid-user');

      return const Result<void>.failure(AppError.unknown);
    }

    final uid = user.uid;

    try {
      await _reauthenticate(
        user: user,
        email: email,
        currentPassword: input.currentPassword,
      );
      await user.delete();
      _logger.info('auth.delete-account.auth-provider.success');
    } on FirebaseAuthException catch (error, stackTrace) {
      _logger.error(
        'auth.delete-account.auth-provider.failed',
        error: error,
        stackTrace: stackTrace,
      );

      return Result<void>.failure(_mapDeleteAccountAuthError(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.delete-account.auth-provider.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppError.unknown);
    }

    try {
      await _usersDataSource.deleteUser(uid: uid);
      _logger.info('auth.delete-account.users-document.success');

      return const Result<void>.success(null);
    } on FirebaseException catch (error, stackTrace) {
      _logger.error(
        'auth.delete-account.users-document.failed',
        error: error,
        stackTrace: stackTrace,
      );
      await _cleanupDeletedAccountDocument(uid: uid);

      return Result<void>.failure(_mapFirestoreError(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.delete-account.users-document.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );
      await _cleanupDeletedAccountDocument(uid: uid);

      return const Result<void>.failure(AppError.unknown);
    }
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

  /// currentPassword 기반 recent login 확보.
  Future<void> _reauthenticate({
    required User user,
    required String email,
    required String currentPassword,
  }) {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    return user.reauthenticateWithCredential(credential);
  }

  /// 계정 삭제 후 남아 있을 수 있는 users 문서를 최대 5회 정리한다.
  Future<bool> _cleanupDeletedAccountDocument({required String uid}) async {
    for (var attempt = 1; attempt <= 5; attempt++) {
      try {
        await _usersDataSource.deleteUser(uid: uid);
        _logger.info(
          'auth.delete-account.users-document.cleanup.success.$attempt',
        );

        return true;
      } on FirebaseException catch (error, stackTrace) {
        _logger.warn(
          'auth.delete-account.users-document.cleanup.retry.$attempt.'
          '${error.code}',
        );

        if (attempt == 5) {
          _logger.error(
            'auth.delete-account.users-document.cleanup.failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
      } catch (error, stackTrace) {
        _logger.warn(
          'auth.delete-account.users-document.cleanup.retry.$attempt.unknown',
        );

        if (attempt == 5) {
          _logger.error(
            'auth.delete-account.users-document.cleanup.failed.unknown',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }

    return false;
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

  /// FirebaseAuthException -> change password AppError 매핑.
  AppError _mapChangePasswordError(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return AppError.wrongPassword;
      case 'weak-password':
        return AppError.weakPassword;
      case 'network-request-failed':
        return AppError.network;
      default:
        return AppError.unknown;
    }
  }

  /// FirebaseAuthException -> delete account AppError 매핑.
  AppError _mapDeleteAccountAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return AppError.wrongPassword;
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
}
