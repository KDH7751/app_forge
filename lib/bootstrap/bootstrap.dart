import 'dart:async';

// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Bootstrap
///
/// 역할:
/// - runtime bootstrap host로 app 설정 3파일을 소비해 RouterEngine과 redirect bridge를 조립함.
///
/// 경계:
/// - source of truth가 아니며 app 설정은 `lib/app`의 3파일로만 수렴함.
/// - `app_config`, `app_plugins`, `app_features`를 소비만 하고 설정을 재정의하지 않음.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_forge/engine/engine.dart';

import '../app/app_config.dart';
import '../app/app_features.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/state/auth_session_provider.dart';

/// runtime bootstrap host widget.
class Bootstrap extends StatefulWidget {
  const Bootstrap({
    super.key,
    this.overrides = const <Override>[],
    required this.errorHub,
  });

  final List<Override> overrides;
  final ErrorHub errorHub;

  /// stateful bootstrap state 생성.
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

/// Router와 bridge notifier를 소유하는 runtime bootstrap state.
class _BootstrapState extends State<Bootstrap> {
  late final NavigationStateNotifier _navigationNotifier;
  late final ValueNotifier<AppAuthRedirectStatus> _authRedirectNotifier;
  late final RouterEngine _routerEngine;
  late final GoRouter _router;
  late final ErrorHub _errorHub;

  /// 초기 navigation 상태와 redirect bridge 구성.
  @override
  void initState() {
    super.initState();

    _errorHub = widget.errorHub;
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
      child: ErrorHubScope(
        errorHub: _errorHub,
        child: _BootstrapView(
          router: _router,
          authRedirectNotifier: _authRedirectNotifier,
          errorHub: _errorHub,
        ),
      ),
    );
  }
}

/// Provider bridge를 포함한 runtime host view.
class _BootstrapView extends ConsumerStatefulWidget {
  const _BootstrapView({
    required this.router,
    required this.authRedirectNotifier,
    required this.errorHub,
  });

  final GoRouter router;
  final ValueNotifier<AppAuthRedirectStatus> authRedirectNotifier;
  final ErrorHub errorHub;

  @override
  ConsumerState<_BootstrapView> createState() => _BootstrapViewState();
}

/// auth session provider와 redirect notifier를 연결하는 state.
class _BootstrapViewState extends ConsumerState<_BootstrapView> {
  ProviderSubscription<AsyncValue<AuthSession?>>? _authSessionSubscription;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<ErrorEvent>? _errorSubscription;

  @override
  void initState() {
    super.initState();

    _authSessionSubscription = ref.listenManual<AsyncValue<AuthSession?>>(
      authSessionProvider,
      (_, next) => _syncRedirectStatus(next),
      fireImmediately: true,
    );
    _errorSubscription = widget.errorHub.stream.listen(_handleErrorEvent);
  }

  @override
  void dispose() {
    unawaited(_errorSubscription?.cancel());
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

  void _handleErrorEvent(ErrorEvent event) {
    if (!event.decision.shouldNotify) {
      return;
    }

    final message = mapAppErrorNotificationText(event.envelope.domainError);

    if (message == null || message.isEmpty) {
      return;
    }

    _scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: appConfig.appTitle,
      debugShowCheckedModeBanner: appConfig.showDebugBanner,
      theme: appConfig.theme,
      routerConfig: widget.router,
    );
  }
}
