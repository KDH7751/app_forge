import 'package:firebase_auth/firebase_auth.dart';
import '../../../foundation/foundation.dart';

import '../../domain/actions/logout_action.dart';
import '../../domain/auth_logger.dart';

/// Firebase 기반 logout 실행.
class FirebaseLogoutAction implements LogoutAction {
  FirebaseLogoutAction({
    required FirebaseAuth firebaseAuth,
    required AuthLogger logger,
  }) : _firebaseAuth = firebaseAuth,
       _logger = logger;

  final FirebaseAuth _firebaseAuth;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute() async {
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
}
