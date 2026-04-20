import 'package:firebase_auth/firebase_auth.dart';
import '../../../foundation/foundation.dart';

import '../../domain/actions/signup_action.dart';
import '../../domain/auth_logger.dart';
import '../datasources/users_document_datasource.dart';
import 'firebase_auth_action_support.dart';

/// Firebase 기반 signup 실행.
class FirebaseSignupAction implements SignupAction {
  FirebaseSignupAction({
    required FirebaseAuth firebaseAuth,
    required UsersDocumentDataSource usersDataSource,
    required AuthLogger logger,
  }) : _firebaseAuth = firebaseAuth,
       _usersDataSource = usersDataSource,
       _logger = logger;

  final FirebaseAuth _firebaseAuth;
  final UsersDocumentDataSource _usersDataSource;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute({
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
      final resolvedEmail = resolveUserEmail(user);

      if (user == null || resolvedEmail == null) {
        _logger.warn('auth.signup.invalid-user');
        await safeRollbackSignOut(firebaseAuth: _firebaseAuth, logger: _logger);

        return const Result<void>.failure(AppFailure.unknown);
      }

      try {
        await _usersDataSource.upsertUser(uid: user.uid, email: resolvedEmail);
      } on FirebaseException catch (error, stackTrace) {
        _logger.error(
          'auth.signup.users-upsert.failed',
          error: error,
          stackTrace: stackTrace,
        );
        await safeRollbackSignOut(firebaseAuth: _firebaseAuth, logger: _logger);

        return Result<void>.failure(mapFirestoreFailure(error));
      } catch (error, stackTrace) {
        _logger.error(
          'auth.signup.users-upsert.failed.unknown',
          error: error,
          stackTrace: stackTrace,
        );
        await safeRollbackSignOut(firebaseAuth: _firebaseAuth, logger: _logger);

        return const Result<void>.failure(AppFailure.unknown);
      }

      _logger.info('auth.signup.success');

      return const Result<void>.success(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      _logger.error(
        'auth.signup.firebase-auth.failed',
        error: error,
        stackTrace: stackTrace,
      );

      return Result<void>.failure(mapSignupFailure(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.signup.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppFailure.unknown);
    }
  }
}
