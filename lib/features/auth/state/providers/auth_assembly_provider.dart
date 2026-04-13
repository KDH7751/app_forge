import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/actions/firebase_change_password_action.dart';
import '../../data/actions/firebase_delete_account_action.dart';
import '../../data/actions/firebase_login_action.dart';
import '../../data/actions/firebase_logout_action.dart';
import '../../data/actions/firebase_reset_password_action.dart';
import '../../data/actions/firebase_signup_action.dart';
import '../../data/datasources/users_document_datasource.dart';
import '../../data/factories/auth_runtime_factory.dart';
import '../../domain/actions/change_password_action.dart';
import '../../domain/actions/delete_account_action.dart';
import '../../domain/actions/login_action.dart';
import '../../domain/actions/logout_action.dart';
import '../../domain/actions/reset_password_action.dart';
import '../../domain/actions/signup_action.dart';
import '../../domain/core/auth_logger.dart';
import '../../domain/session/auth_session.dart';
import 'auth_setup_provider.dart';
import 'auth_runtime_provider.dart';
import 'auth_session_models.dart';

/// 선택된 auth provider set이 노출하는 concrete 조립 표면.
///
/// auth action provider와 session provider는 이 인터페이스만 보고 동작하므로,
/// 새로운 provider set이 추가되면 action 실행과 session 관찰을 함께 이 계약에 맞춰 제공해야 한다.
abstract interface class AuthSetAssembly {
  AuthProviderSet get provider;

  Set<AuthCapability> get supportedCapabilities;

  LoginAction? get loginAction;
  SignupAction? get signupAction;
  ResetPasswordAction? get resetPasswordAction;
  ChangePasswordAction? get changePasswordAction;
  DeleteAccountAction? get deleteAccountAction;
  LogoutAction get logoutAction;

  Stream<Authenticated?> watchSessions();

  AuthProviderInvalidationWatcher createInvalidationWatcher({
    required Duration probeInterval,
  });
}

/// Firebase auth provider set이 제공하는 concrete 구현 묶음.
///
/// app은 이 클래스를 직접 고르지 않고, `authAssemblyProvider`
/// 가 `AuthSetup`을 보고 선택한다.
class FirebaseAuthAssembly implements AuthSetAssembly {
  FirebaseAuthAssembly({
    required FirebaseAuthConfig config,
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
  AuthProviderSet get provider => AuthProviderSet.firebaseAuth;

  @override
  Set<AuthCapability> get supportedCapabilities => const <AuthCapability>{
    AuthCapability.login,
    AuthCapability.signup,
    AuthCapability.sendPasswordResetEmail,
    AuthCapability.changePassword,
    AuthCapability.deleteAccount,
  };

  @override
  LoginAction get loginAction => FirebaseLoginAction(
    firebaseAuth: _firebaseAuth,
    usersDataSource: _usersDataSource,
    logger: _logger,
  );

  @override
  SignupAction get signupAction => FirebaseSignupAction(
    firebaseAuth: _firebaseAuth,
    usersDataSource: _usersDataSource,
    logger: _logger,
  );

  @override
  ResetPasswordAction get resetPasswordAction =>
      FirebaseResetPasswordAction(firebaseAuth: _firebaseAuth, logger: _logger);

  @override
  ChangePasswordAction get changePasswordAction => FirebaseChangePasswordAction(
    firebaseAuth: _firebaseAuth,
    logger: _logger,
  );

  @override
  DeleteAccountAction get deleteAccountAction => FirebaseDeleteAccountAction(
    firebaseAuth: _firebaseAuth,
    usersDataSource: _usersDataSource,
    logger: _logger,
  );

  @override
  LogoutAction get logoutAction =>
      FirebaseLogoutAction(firebaseAuth: _firebaseAuth, logger: _logger);

  @override
  Stream<Authenticated?> watchSessions() {
    return watchAuthSessions(_firebaseAuth);
  }

  @override
  AuthProviderInvalidationWatcher createInvalidationWatcher({
    required Duration probeInterval,
  }) {
    return (uid) => _watchFirebaseAuthProviderInvalidation(
      firebaseAuth: _firebaseAuth,
      uid: uid,
      probeInterval: probeInterval,
    );
  }
}

/// 현재 app 입력에 대응하는 auth provider set assembly 진입점.
///
/// auth action/facade/session provider는 이 provider를 통해
/// 같은 provider set 기준을 공유한다.
final authAssemblyProvider = Provider<AuthSetAssembly>((ref) {
  final setup = ref.watch(authSetupProvider);

  switch (setup.provider) {
    case AuthProviderSet.firebaseAuth:
      final config = setup.config;

      if (config is! FirebaseAuthConfig) {
        throw StateError(
          'Auth provider `${setup.provider.name}` requires FirebaseAuthConfig.',
        );
      }

      return FirebaseAuthAssembly(
        config: config,
        firebaseAuth: ref.watch(firebaseAuthProvider),
        usersDataSource: ref.watch(usersDocumentDataSourceProvider),
        logger: ref.watch(authLoggerProvider),
      );
  }
});

/// FirebaseAuth의 server-side delete/disable을 polling으로 감지하는 내부 watcher.
///
/// session provider는 provider set이 제공한 watcher만 소비하므로,
/// Firebase 전용 invalidation 해석 세부는 이 파일 안에 남긴다.
Stream<AuthSessionInvalidation?> _watchFirebaseAuthProviderInvalidation({
  required FirebaseAuth firebaseAuth,
  required String uid,
  required Duration probeInterval,
}) {
  return Stream<AuthSessionInvalidation?>.multi((controller) {
    Timer? probeTimer;

    Future<void> probe() async {
      final user = firebaseAuth.currentUser;

      if (user == null || user.uid != uid) {
        controller.add(null);
        return;
      }

      try {
        await user.reload();
        final refreshedUser = firebaseAuth.currentUser;

        if (refreshedUser == null || refreshedUser.uid != uid) {
          controller.add(
            AuthSessionInvalidation(
              uid: uid,
              reason: AuthSessionInvalidationReason.missingAuthProviderUser,
            ),
          );
          return;
        }

        controller.add(null);
      } on FirebaseAuthException catch (error) {
        switch (error.code) {
          case 'user-not-found':
            controller.add(
              AuthSessionInvalidation(
                uid: uid,
                reason: AuthSessionInvalidationReason.missingAuthProviderUser,
              ),
            );
            return;
          case 'user-disabled':
            controller.add(
              AuthSessionInvalidation(
                uid: uid,
                reason: AuthSessionInvalidationReason.disabledAuthProviderUser,
              ),
            );
            return;
          default:
            controller.add(null);
            return;
        }
      } catch (_) {
        controller.add(null);
      }
    }

    unawaited(probe());
    probeTimer = Timer.periodic(probeInterval, (_) => unawaited(probe()));

    controller.onCancel = () {
      probeTimer?.cancel();
    };
  });
}
