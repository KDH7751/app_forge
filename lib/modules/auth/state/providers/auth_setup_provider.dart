import 'package:flutter_riverpod/flutter_riverpod.dart';

/// app이 auth 영역에 대해 고를 수 있는 provider set 식별자.
///
/// auth assembly는 이 enum을 기준으로 concrete action/session 조립 방향을 정한다.
enum AuthProviderSet { firebaseAuth, apiTestHarness }

/// auth provider set이 기본적으로 제공할 수 있는 capability 집합.
///
/// app은 이 목록 바깥 capability를 새로 만들지 못하고,
/// provider set이 이미 지원하는 항목만 정책으로 끌 수 있다.
enum AuthCapability {
  login,
  signup,
  sendPasswordResetEmail,
  changePassword,
  deleteAccount,
}

/// provider set 전체에 적용되는 최소 설정 계약.
///
/// 개별 endpoint나 action별 runtime 세부는 여기로 올리지 않는다.
sealed class AuthConfig {
  const AuthConfig();
}

/// Firebase auth provider set 최소 설정.
///
/// 현재는 선택만으로 충분해 비어 있지만,
/// app이 auth set 전체에 넘길 최소 설정 경계를 보여주기 위해 타입을 유지한다.
class FirebaseAuthConfig extends AuthConfig {
  const FirebaseAuthConfig({this.providerLabel = 'Firebase'});

  final String providerLabel;
}

/// API-style auth provider set test harness config.
///
/// This is intentionally minimal for the Phase 3.6 follow-up. Endpoint, parser,
/// status mapping, and concrete client wiring stay inside the auth module.
class ApiTestHarnessAuthConfig extends AuthConfig {
  const ApiTestHarnessAuthConfig({this.providerLabel = 'API test harness'});

  final String providerLabel;
}

/// Debug/verification metadata for the selected auth provider.
class AuthProviderMetadata {
  const AuthProviderMetadata({required this.label});

  final String label;
}

/// app이 provider set 위에 덮는 최종 활성화 정책.
///
/// 선택된 provider set이 지원하는 capability 중 일부만 끄는 용도이며,
/// auth assembly는 이 정책을 action 노출 여부에만 반영한다.
class AuthActivationPolicy {
  const AuthActivationPolicy({
    this.disabledCapabilities = const <AuthCapability>{},
  });

  final Set<AuthCapability> disabledCapabilities;

  bool disables(AuthCapability capability) {
    return disabledCapabilities.contains(capability);
  }
}

/// auth/state assembly가 bootstrap override로 받는 app-origin 입력 묶음.
///
/// domain model이 아니라 composition input이며,
/// auth facade/action/session provider가 공통으로 참조하는 기준값이다.
class AuthSetup {
  const AuthSetup({
    required this.provider,
    required this.config,
    required this.policy,
  });

  final AuthProviderSet provider;
  final AuthConfig config;
  final AuthActivationPolicy policy;
}

/// bootstrap이 override하지 않을 때 사용하는 기본 auth 입력 provider.
///
/// 테스트나 app bootstrap은 이 provider를 override해서
/// 실제 provider set 선택과 activation policy를 주입한다.
final authSetupProvider = Provider<AuthSetup>((ref) {
  return const AuthSetup(
    provider: AuthProviderSet.firebaseAuth,
    config: FirebaseAuthConfig(),
    policy: AuthActivationPolicy(),
  );
});

/// Metadata for UI/debug verification of the selected auth provider.
///
/// This value is display-only and must not drive redirect, session, or failure
/// decisions.
final authProviderMetadataProvider = Provider<AuthProviderMetadata>((ref) {
  final setup = ref.watch(authSetupProvider);

  return AuthProviderMetadata(label: _providerLabel(setup));
});

String _providerLabel(AuthSetup setup) {
  final config = setup.config;

  return switch ((setup.provider, config)) {
    (AuthProviderSet.firebaseAuth, FirebaseAuthConfig(:final providerLabel)) =>
      providerLabel,
    (
      AuthProviderSet.apiTestHarness,
      ApiTestHarnessAuthConfig(:final providerLabel),
    ) =>
      providerLabel,
    (AuthProviderSet.firebaseAuth, _) => 'Firebase',
    (AuthProviderSet.apiTestHarness, _) => 'API test harness',
  };
}
