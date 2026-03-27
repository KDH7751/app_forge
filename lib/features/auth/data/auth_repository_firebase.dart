// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Firebase Auth Repository
///
/// 역할:
/// - FirebaseAuth login/logout과 users 문서 upsert를 단일 성공 흐름으로 묶음.
///
/// 경계:
/// - UI/controller는 Firebase나 Firestore를 직접 알지 않음.
/// - users upsert 실패 시 rollback signOut은 repository 내부에서 닫음.
/// ===================================================================

import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_error.dart';
import '../domain/app_logger.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
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
  Future<Result<AuthSession>> login({
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

        return const Result<AuthSession>.failure(AppError.loginFailed);
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

        return Result<AuthSession>.failure(_mapFirestoreError(error));
      } catch (error, stackTrace) {
        _logger.error(
          'auth.login.users-upsert.failed.unknown',
          error: error,
          stackTrace: stackTrace,
        );
        await _safeRollbackSignOut();

        return const Result<AuthSession>.failure(AppError.loginFailed);
      }

      _logger.info('auth.login.success');

      return Result<AuthSession>.success(
        AuthSession(uid: user.uid, email: resolvedEmail),
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      _logger.error(
        'auth.login.firebase-auth.failed',
        error: error,
        stackTrace: stackTrace,
      );

      return Result<AuthSession>.failure(_mapAuthError(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.login.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<AuthSession>.failure(AppError.loginFailed);
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

      return const Result<void>.failure(AppError.loginFailed);
    } catch (error, stackTrace) {
      _logger.error(
        'auth.logout.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppError.loginFailed);
    }
  }

  /// 현재 auth session 조회.
  @override
  AuthSession? currentSession() {
    final user = _firebaseAuth.currentUser;
    final email = _resolveUserEmail(user);

    if (user == null || email == null) {
      return null;
    }

    return AuthSession(uid: user.uid, email: email);
  }

  /// auth session 변경 스트림 변환.
  @override
  Stream<AuthSession?> watchSession() {
    return _firebaseAuth.authStateChanges().map((user) {
      final email = _resolveUserEmail(user);

      if (user == null || email == null) {
        return null;
      }

      return AuthSession(uid: user.uid, email: email);
    });
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

  /// FirebaseAuthException -> AppError 매핑.
  AppError _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AppError.userNotFound;
      case 'wrong-password':
        return AppError.wrongPassword;
      case 'network-request-failed':
        return AppError.network;
      default:
        return AppError.loginFailed;
    }
  }

  /// Firestore 오류 -> AppError 매핑.
  AppError _mapFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'unavailable':
      case 'network-request-failed':
        return AppError.network;
      default:
        return AppError.loginFailed;
    }
  }
}
