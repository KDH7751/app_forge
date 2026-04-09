import 'dart:async';

// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Bootstrap
///
/// 역할:
/// - app root UI와 runtime 연결 지점을 조립한다.
///
/// 흐름:
/// - 초기 navigation 상태를 만들고
/// - auth 상태와 redirect 입력을 연결하며
/// - 전역 에러를 UI 알림으로 연결한다.
///
/// 영향:
/// - app 시작 직후 화면 흐름과 전역 에러 노출 방식이 여기서 결정된다.
///
/// 주의:
/// - 전역 listener는 중복 등록되면 안 된다.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_forge/engine/engine.dart';

import '../app/app_config.dart';
import '../app/app_features.dart';
import '../features/auth/state/auth_repository_provider.dart';
import '../features/auth/state/auth_session_provider.dart';

/// app root runtime 연결을 시작하는 host widget.
class Bootstrap extends StatefulWidget {
  const Bootstrap({
    super.key,
    this.overrides = const <Override>[],
    required this.errorHub,
  });

  final List<Override> overrides;
  final ErrorHub errorHub;

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

/// app 시작에 필요한 router와 notifier를 보관하는 state.
class _BootstrapState extends State<Bootstrap> {
  late final NavigationStateNotifier _navigationNotifier;
  late final ValueNotifier<AppAuthRedirectStatus> _authRedirectNotifier;
  late final RouterEngine _routerEngine;
  late final GoRouter _router;
  late final ErrorHub _errorHub;

  /// app 시작 시 필요한 연결을 한 번만 만든다.
  ///
  /// 여기서 구성한 초기 상태와 redirect 연결에 따라
  /// 첫 화면 흐름이 달라진다.
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

  /// app 종료 시 router와 notifier를 정리한다.
  @override
  void dispose() {
    _router.dispose();
    _authRedirectNotifier.dispose();
    _navigationNotifier.dispose();
    super.dispose();
  }

  /// 현재 인증 상태를 redirect 판단 입력으로 연결한다.
  ///
  /// 이 연결 방식이 바뀌면
  /// app 전역 화면 접근 흐름도 함께 달라진다.
  String? _handleAppRedirect(BuildContext context, GoRouterState state) {
    return resolveAppRedirect(
      authStatus: _authRedirectNotifier.value,
      location: state.uri.toString(),
    );
  }

  /// app root에 필요한 provider와 ErrorHub scope를 연결한다.
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

/// auth 상태와 전역 에러 listener를 포함한 root view.
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

/// app 전역 listener를 관리하는 state.
class _BootstrapViewState extends ConsumerState<_BootstrapView> {
  ProviderSubscription<AsyncValue<AuthSessionObservation>>?
  _authSessionObservationSubscription;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<ErrorEvent>? _errorSubscription;
  String? _pendingForcedLogoutUid;

  /// auth 상태와 ErrorHub stream을 앱 시작 시 바로 연결한다.
  ///
  /// 이 listener들은 app 전체에서 한 번만 살아 있어야
  /// redirect와 전역 알림이 중복되지 않는다.
  @override
  void initState() {
    super.initState();

    _authSessionObservationSubscription = ref
        .listenManual<AsyncValue<AuthSessionObservation>>(
          authSessionObservationProvider,
          (_, next) => _handleAuthSessionObservationChanged(next),
          fireImmediately: true,
        );
    _errorSubscription = widget.errorHub.stream.listen(_handleErrorEvent);
  }

  /// 등록한 전역 listener를 정리한다.
  @override
  void dispose() {
    unawaited(_errorSubscription?.cancel());
    _authSessionObservationSubscription?.close();
    super.dispose();
  }

  /// 단일 observation 입력으로 redirect와 강제 logout을 연결한다.
  void _handleAuthSessionObservationChanged(
    AsyncValue<AuthSessionObservation> observationValue,
  ) {
    final nextStatus = _resolveRedirectStatus(observationValue);

    if (widget.authRedirectNotifier.value != nextStatus) {
      widget.authRedirectNotifier.value = nextStatus;
    }

    if (observationValue case AsyncData<AuthSessionObservation>(
      value: final observation,
    )) {
      _syncForcedLogout(observation);
    }
  }

  AppAuthRedirectStatus _resolveRedirectStatus(
    AsyncValue<AuthSessionObservation> observationValue,
  ) {
    if (observationValue
        case AsyncData<AuthSessionObservation>(value: final observation)
        when observation.session != null &&
            (!observation.hasResolvedUserDocumentState ||
                !observation.hasResolvedAuthProviderState)) {
      return AppAuthRedirectStatus.unknown;
    }

    if (observationValue case AsyncData<AuthSessionObservation>(
      value: final observation,
    ) when observation.invalidation != null) {
      return AppAuthRedirectStatus.invalid;
    }

    return switch (observationValue) {
      AsyncData<AuthSessionObservation>(value: final observation)
          when observation.session != null =>
        AppAuthRedirectStatus.authenticated,
      AsyncData<AuthSessionObservation>() =>
        AppAuthRedirectStatus.unauthenticated,
      AsyncError<AuthSessionObservation>() =>
        AppAuthRedirectStatus.unauthenticated,
      _ => AppAuthRedirectStatus.unknown,
    };
  }

  /// 같은 session uid에 대한 강제 logout 중복 호출을 막는다.
  void _syncForcedLogout(AuthSessionObservation observation) {
    final invalidation = observation.invalidation;

    if (observation.session == null || invalidation == null) {
      _pendingForcedLogoutUid = null;
      return;
    }

    if (_pendingForcedLogoutUid == invalidation.uid) {
      return;
    }

    _pendingForcedLogoutUid = invalidation.uid;
    unawaited(ref.read(authRepositoryProvider).logout());
  }

  /// ErrorHub stream을 구독해 전역 에러를 UI 알림으로 전달한다.
  ///
  /// 이 listener는 app 전체에서 단 하나만 존재해야 한다.
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

  /// app root MaterialApp을 렌더링한다.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppAuthRedirectStatus>(
      valueListenable: widget.authRedirectNotifier,
      builder: (context, authStatus, _) {
        if (authStatus == AppAuthRedirectStatus.unknown) {
          return MaterialApp(
            scaffoldMessengerKey: _scaffoldMessengerKey,
            title: appConfig.appTitle,
            debugShowCheckedModeBanner: appConfig.showDebugBanner,
            theme: appConfig.theme,
            home: const _BootstrapPendingView(),
          );
        }

        return MaterialApp.router(
          scaffoldMessengerKey: _scaffoldMessengerKey,
          title: appConfig.appTitle,
          debugShowCheckedModeBanner: appConfig.showDebugBanner,
          theme: appConfig.theme,
          routerConfig: widget.router,
        );
      },
    );
  }
}

/// auth session과 server state가 맞춰질 때까지 잠깐 보여주는 대기 화면.
class _BootstrapPendingView extends StatelessWidget {
  const _BootstrapPendingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
