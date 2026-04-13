import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_facade.dart';
import 'auth_action_provider.dart';

/// auth facade 조립 provider.
final authFacadeProvider = Provider<AuthFacade>((ref) {
  return DefaultAuthFacade(
    loginAction: ref.watch(loginActionProvider),
    signupAction: ref.watch(signupActionProvider),
    resetPasswordAction: ref.watch(resetPasswordActionProvider),
    changePasswordAction: ref.watch(changePasswordActionProvider),
    deleteAccountAction: ref.watch(deleteAccountActionProvider),
    logoutAction: ref.watch(logoutActionProvider),
  );
});
