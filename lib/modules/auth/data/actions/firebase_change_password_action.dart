import 'package:firebase_auth/firebase_auth.dart';
import '../../../foundation/foundation.dart';

import '../../domain/actions/change_password_action.dart';
import '../../domain/auth_logger.dart';
import '../../domain/models/change_password_input.dart';
import 'firebase_auth_action_support.dart';

/// Firebase 기반 change password 실행.
class FirebaseChangePasswordAction implements ChangePasswordAction {
  FirebaseChangePasswordAction({
    required FirebaseAuth firebaseAuth,
    required AuthLogger logger,
  }) : _firebaseAuth = firebaseAuth,
       _logger = logger;

  final FirebaseAuth _firebaseAuth;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute(ChangePasswordInput input) async {
    _logger.info('auth.change-password.start');

    final user = _firebaseAuth.currentUser;
    final email = resolveUserEmail(user);

    if (user == null || email == null) {
      _logger.warn('auth.change-password.invalid-user');

      return const Result<void>.failure(AppFailure.unknown);
    }

    try {
      await reauthenticate(
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

      return Result<void>.failure(mapChangePasswordFailure(error));
    } catch (error, stackTrace) {
      _logger.error(
        'auth.change-password.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppFailure.unknown);
    }
  }
}
