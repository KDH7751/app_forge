import 'package:firebase_auth/firebase_auth.dart';

import '../../../foundation/foundation.dart';
import '../../domain/auth_logger.dart';
import '../../domain/validation/auth_field_keys.dart';
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

/// Firebase login 오류를 auth AppFailure로 매핑한다.
AppFailure mapLoginFailure(FirebaseAuthException error) {
  switch (error.code) {
    // login은 계정 존재 여부를 노출하는 흐름이 아니라 credential submit 흐름이므로,
    // 같은 raw fact라도 reset과 달리 invalidCredentials로 닫는다.
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return AppFailure.invalidCredentials;
    // action failure contract의 unauthorized는 현재 login action을 완료할 수 없다는 뜻이다.
    // Phase 3.5 session invalid public contract의 InvalidReason.disabled를 대체하지 않는다.
    case 'user-disabled':
      return AppFailure.unauthorized;
    case 'invalid-email':
      return const AppFailure.validation(
        fieldErrors: <String, ValidationFieldError>{
          AuthFailureField.email: ValidationFieldError.invalid,
        },
      );
    case 'too-many-requests':
      return AppFailure.rateLimited;
    case 'network-request-failed':
      return AppFailure.network;
    default:
      return AppFailure.unknown;
  }
}

/// Firebase signup 오류를 auth AppFailure로 매핑한다.
AppFailure mapSignupFailure(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return AppFailure.conflict;
    case 'weak-password':
      return const AppFailure.validation(
        fieldErrors: <String, ValidationFieldError>{
          AuthFailureField.password: ValidationFieldError.tooWeak,
        },
      );
    case 'invalid-email':
      return const AppFailure.validation(
        fieldErrors: <String, ValidationFieldError>{
          AuthFailureField.email: ValidationFieldError.invalid,
        },
      );
    case 'operation-not-allowed':
      return AppFailure.permissionDenied;
    case 'too-many-requests':
      return AppFailure.rateLimited;
    case 'network-request-failed':
      return AppFailure.network;
    default:
      return AppFailure.unknown;
  }
}

/// Firebase reset password 오류를 auth AppFailure로 매핑한다.
AppFailure mapResetFailure(FirebaseAuthException error) {
  switch (error.code) {
    // reset은 account existence를 확인하는 recovery 흐름이므로,
    // 같은 raw fact라도 login과 달리 notFound로 정규화한다.
    case 'user-not-found':
      return AppFailure.notFound;
    case 'invalid-email':
      return const AppFailure.validation(
        fieldErrors: <String, ValidationFieldError>{
          AuthFailureField.email: ValidationFieldError.invalid,
        },
      );
    case 'too-many-requests':
      return AppFailure.rateLimited;
    case 'network-request-failed':
      return AppFailure.network;
    default:
      return AppFailure.unknown;
  }
}

/// Firebase change password 오류를 auth AppFailure로 매핑한다.
AppFailure mapChangePasswordFailure(FirebaseAuthException error) {
  switch (error.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return AppFailure.invalidCredentials;
    case 'weak-password':
      return const AppFailure.validation(
        fieldErrors: <String, ValidationFieldError>{
          AuthFailureField.newPassword: ValidationFieldError.tooWeak,
        },
      );
    // 여기의 unauthorized도 action 실행 실패 의미이며,
    // session invalid public contract의 disabled/invalid reason 축과는 별개다.
    case 'requires-recent-login':
      return AppFailure.unauthorized;
    case 'too-many-requests':
      return AppFailure.rateLimited;
    case 'network-request-failed':
      return AppFailure.network;
    default:
      return AppFailure.unknown;
  }
}

/// Firebase delete account auth-side 오류를 auth AppFailure로 매핑한다.
AppFailure mapDeleteAccountAuthFailure(FirebaseAuthException error) {
  switch (error.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return AppFailure.invalidCredentials;
    // 여기의 unauthorized도 action 실행 실패 의미이며,
    // session invalid public contract의 disabled/invalid reason 축과는 별개다.
    case 'requires-recent-login':
      return AppFailure.unauthorized;
    case 'too-many-requests':
      return AppFailure.rateLimited;
    case 'network-request-failed':
      return AppFailure.network;
    default:
      return AppFailure.unknown;
  }
}

/// Firestore users 문서 작업 오류를 auth AppFailure로 매핑한다.
AppFailure mapFirestoreFailure(FirebaseException error) {
  switch (error.code) {
    case 'permission-denied':
      return AppFailure.permissionDenied;
    case 'not-found':
      return AppFailure.notFound;
    case 'already-exists':
    case 'aborted':
      return AppFailure.conflict;
    case 'resource-exhausted':
      return AppFailure.rateLimited;
    case 'network-request-failed':
      return AppFailure.network;
    case 'unavailable':
      return AppFailure.unavailable;
    default:
      return AppFailure.unknown;
  }
}
