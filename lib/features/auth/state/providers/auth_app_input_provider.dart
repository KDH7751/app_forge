import 'package:flutter_riverpod/flutter_riverpod.dart';

/// app이 auth에 연결한 backend family.
enum AuthBackendFamily { firebase }

/// app이 auth 기능별로 연결한 상태.
class AuthCapabilityConnections {
  const AuthCapabilityConnections({
    required this.loginConnected,
    required this.signupConnected,
    required this.resetPasswordConnected,
    required this.changePasswordConnected,
    required this.deleteAccountConnected,
  });

  final bool loginConnected;
  final bool signupConnected;
  final bool resetPasswordConnected;
  final bool changePasswordConnected;
  final bool deleteAccountConnected;
}

/// auth/state assembly가 소비하는 app-origin auth 입력.
class AuthAppInput {
  const AuthAppInput({required this.backendFamily, required this.capabilities});

  final AuthBackendFamily backendFamily;
  final AuthCapabilityConnections capabilities;
}

/// auth/state assembly가 app에서 주입받는 입력 provider.
final authAppInputProvider = Provider<AuthAppInput>((ref) {
  return const AuthAppInput(
    backendFamily: AuthBackendFamily.firebase,
    capabilities: AuthCapabilityConnections(
      loginConnected: false,
      signupConnected: false,
      resetPasswordConnected: false,
      changePasswordConnected: false,
      deleteAccountConnected: false,
    ),
  );
});
