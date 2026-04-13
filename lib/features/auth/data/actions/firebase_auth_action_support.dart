import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/core/app_error.dart';
import '../../domain/core/auth_logger.dart';
import '../datasources/users_document_datasource.dart';

String? resolveUserEmail(User? user) {
  final email = user?.email;

  if (email == null || email.isEmpty) {
    return null;
  }

  return email;
}

Future<void> safeRollbackSignOut({
  required FirebaseAuth firebaseAuth,
  required AuthLogger logger,
}) async {
  try {
    await firebaseAuth.signOut();
    logger.info('auth.login.rollback-signout.success');
  } catch (error, stackTrace) {
    logger.error(
      'auth.login.rollback-signout.failed',
      error: error,
      stackTrace: stackTrace,
    );
    logger.warn(
      'auth.login.rollback-signout.fallback: partial auth state may remain '
      'until the next auth refresh or explicit logout attempt',
    );
  }
}

Future<void> reauthenticate({
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

Future<bool> cleanupDeletedAccountDocument({
  required UsersDocumentDataSource usersDataSource,
  required AuthLogger logger,
  required String uid,
}) async {
  for (var attempt = 1; attempt <= 5; attempt++) {
    try {
      await usersDataSource.deleteUser(uid: uid);
      logger.info(
        'auth.delete-account.users-document.cleanup.success.$attempt',
      );

      return true;
    } on FirebaseException catch (error, stackTrace) {
      logger.warn(
        'auth.delete-account.users-document.cleanup.retry.$attempt.'
        '${error.code}',
      );

      if (attempt == 5) {
        logger.error(
          'auth.delete-account.users-document.cleanup.failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } catch (error, stackTrace) {
      logger.warn(
        'auth.delete-account.users-document.cleanup.retry.$attempt.unknown',
      );

      if (attempt == 5) {
        logger.error(
          'auth.delete-account.users-document.cleanup.failed.unknown',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  return false;
}

AppError mapLoginError(FirebaseAuthException error) {
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

AppError mapSignupError(FirebaseAuthException error) {
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

AppError mapResetError(FirebaseAuthException error) {
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

AppError mapChangePasswordError(FirebaseAuthException error) {
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

AppError mapDeleteAccountAuthError(FirebaseAuthException error) {
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

AppError mapFirestoreError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
      return AppError.network;
    default:
      return AppError.unknown;
  }
}
