import 'package:firebase_auth/firebase_auth.dart';
import '../../../foundation/foundation.dart';

import '../../domain/actions/reset_password_action.dart';
import '../../domain/auth_logger.dart';
import 'firebase_auth_action_support.dart';

/// Firebase 기반 reset password 실행.
class FirebaseResetPasswordAction implements ResetPasswordAction {
  FirebaseResetPasswordAction({
    required FirebaseAuth firebaseAuth,
    required AuthLogger logger,
  }) : _firebaseAuth = firebaseAuth,
       _logger = logger;

  final FirebaseAuth _firebaseAuth;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute({required String email}) async {
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

      return Result<void>.failure(mapResetError(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.reset-password.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppError.unknown);
    }
  }
}
