import 'package:firebase_auth/firebase_auth.dart';

import '../../../foundation/foundation.dart';
import '../../domain/auth_logger.dart';
import '../datasources/users_document_datasource.dart';

/// Firebase action 구현들이 공통으로 쓰는 user email 추출 helper.
///
/// login/signup/changePassword/deleteAccount가 모두 같은 email 허용 규칙을 써야 하므로
/// provider set 내부 helper로 모아둔다.
String? resolveUserEmail(User? user) {
  final email = user?.email;

  if (email == null || email.isEmpty) {
    return null;
  }

  return email;
}

/// users 문서 후처리가 실패했을 때 auth 세션 흔적을 정리하는 공통 rollback helper.
///
/// login/signup concrete action이 함께 사용하므로,
/// rollback 로그와 fallback 메시지도 여기서 일관되게 닫는다.
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

/// recent login이 필요한 action에서 재인증을 수행하는 공통 helper.
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

/// auth provider account 삭제 후 남을 수 있는 users 문서를 즉시 정리한다.
///
/// deleteAccount action의 성공 의미를 승격하지는 않고,
/// partial delete 상황에서 cleanup만 보조한다.
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

/// Firebase login 오류를 auth AppError로 매핑한다.
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

/// Firebase signup 오류를 auth AppError로 매핑한다.
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

/// Firebase reset password 오류를 auth AppError로 매핑한다.
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

/// Firebase change password 오류를 auth AppError로 매핑한다.
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

/// Firebase delete account auth-side 오류를 auth AppError로 매핑한다.
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

/// Firestore users 문서 작업 오류를 auth AppError로 매핑한다.
AppError mapFirestoreError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
      return AppError.network;
    default:
      return AppError.unknown;
  }
}
