// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// App Bootstrap
///
/// 역할:
/// - app composition host로 RouterEngine과 app redirect를 조립함.
///
/// 경계:
/// - app 설정 source of truth가 되지 않음.
/// - redirect 정책 정의 자체는 app_features가 소유함.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_forge/engine/engine.dart';

import 'app_config.dart';
import 'app_features.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/presentation/auth_session_provider.dart';

/// app root composition host.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, this.overrides = const <Override>[]});

  final List<Override> overrides;

  /// stateful composition host state 생성.
  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

/// Router와 navigation notifier를 소유하는 app host state.
class _AppBootstrapState extends State<AppBootstrap> {
  late final NavigationStateNotifier _navigationNotifier;
  late final ValueNotifier<AppAuthRedirectStatus> _authRedirectNotifier;
  late final RouterEngine _routerEngine;
  late final GoRouter _router;

  /// 초기 navigation 상태와 redirect host 구성.
  @override
  void initState() {
    super.initState();

    _navigationNotifier = NavigationStateNotifier(
      initialState: resolveNavigationState(
        location: appConfig.initialLocation,
        routes: appRoutes,
      ),
    );
    // auth session provider bridge가 첫 값을 밀어주기 전까지는 unknown으로 둔다.
    _authRedirectNotifier = ValueNotifier<AppAuthRedirectStatus>(
      AppAuthRedirectStatus.unknown,
    );
    _routerEngine = RouterEngine(
      routes: appRouteTrees,
      initialLocation: appConfig.initialLocation,
      shellConfig: appConfig.shellConfig,
      navigationNotifier: _navigationNotifier,
      redirect: _handleAppRedirect,
      refreshListenable: _authRedirectNotifier,
    );
    _router = _routerEngine.build();
  }

  /// Router와 내부 notifier 정리.
  @override
  void dispose() {
    _router.dispose();
    _authRedirectNotifier.dispose();
    _navigationNotifier.dispose();
    super.dispose();
  }

  /// app redirect를 RouterEngine 입력 시그니처로 연결.
  String? _handleAppRedirect(BuildContext context, GoRouterState state) {
    return resolveAppRedirect(
      authStatus: _authRedirectNotifier.value,
      location: state.uri.toString(),
    );
  }

  /// ProviderScope와 MaterialApp.router 조립.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: <Override>[
        navigationStateNotifierProvider.overrideWithValue(_navigationNotifier),
        ...widget.overrides,
      ],
      child: _AppBootstrapView(
        router: _router,
        authRedirectNotifier: _authRedirectNotifier,
      ),
    );
  }
}

/// Provider bridge를 포함한 app router host.
class _AppBootstrapView extends ConsumerStatefulWidget {
  const _AppBootstrapView({
    required this.router,
    required this.authRedirectNotifier,
  });

  final GoRouter router;
  final ValueNotifier<AppAuthRedirectStatus> authRedirectNotifier;

  @override
  ConsumerState<_AppBootstrapView> createState() => _AppBootstrapViewState();
}

/// auth session provider와 redirect notifier를 연결하는 state.
class _AppBootstrapViewState extends ConsumerState<_AppBootstrapView> {
  ProviderSubscription<AsyncValue<AuthSession?>>? _authSessionSubscription;

  @override
  void initState() {
    super.initState();

    _authSessionSubscription = ref.listenManual<AsyncValue<AuthSession?>>(
      authSessionProvider,
      (_, next) => _syncRedirectStatus(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _authSessionSubscription?.close();
    super.dispose();
  }

  void _syncRedirectStatus(AsyncValue<AuthSession?> sessionValue) {
    final nextStatus = switch (sessionValue) {
      AsyncData<AuthSession?>(value: final session) when session != null =>
        AppAuthRedirectStatus.authenticated,
      AsyncData<AuthSession?>() => AppAuthRedirectStatus.unauthenticated,
      AsyncError<AuthSession?>() => AppAuthRedirectStatus.unauthenticated,
      _ => AppAuthRedirectStatus.unknown,
    };

    if (widget.authRedirectNotifier.value == nextStatus) {
      return;
    }

    widget.authRedirectNotifier.value = nextStatus;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: appConfig.appTitle,
      debugShowCheckedModeBanner: appConfig.showDebugBanner,
      theme: appConfig.theme,
      routerConfig: widget.router,
    );
  }
}
