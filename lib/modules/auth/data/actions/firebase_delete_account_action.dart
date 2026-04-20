import 'package:firebase_auth/firebase_auth.dart';
import '../../../foundation/foundation.dart';

import '../../domain/actions/delete_account_action.dart';
import '../../domain/auth_logger.dart';
import '../../domain/models/delete_account_input.dart';
import '../datasources/users_document_datasource.dart';
import 'firebase_auth_action_support.dart';

/// Firebase 기반 delete account 실행.
class FirebaseDeleteAccountAction implements DeleteAccountAction {
  FirebaseDeleteAccountAction({
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
  Future<Result<void>> execute(DeleteAccountInput input) async {
    _logger.info('auth.delete-account.start');

    final user = _firebaseAuth.currentUser;
    final email = resolveUserEmail(user);

    if (user == null || email == null) {
      _logger.warn('auth.delete-account.invalid-user');

      return const Result<void>.failure(AppFailure.unknown);
    }

    final uid = user.uid;

    try {
      await reauthenticate(
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

      return Result<void>.failure(mapDeleteAccountAuthFailure(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.delete-account.auth-provider.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppFailure.unknown);
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
      await cleanupDeletedAccountDocument(
        usersDataSource: _usersDataSource,
        logger: _logger,
        uid: uid,
      );

      return Result<void>.failure(mapFirestoreFailure(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.delete-account.users-document.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );
      await cleanupDeletedAccountDocument(
        usersDataSource: _usersDataSource,
        logger: _logger,
        uid: uid,
      );

      return const Result<void>.failure(AppFailure.unknown);
    }
  }
}
