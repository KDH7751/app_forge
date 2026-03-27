# Decisions

- 2026-03-23: Engine은 policy, flow, abstraction을 소유하고 concrete 구현은 재사용성을 위해 app이 주입한다.
- 2026-03-23: app은 Engine, Plugin, Feature를 조립하는 composition root다.
- 2026-03-23: Feature는 domain, data, presentation을 함께 가지는 vertical slice로 유지한다.
- 2026-03-23: app과 Feature의 유일한 public Engine import 경로는 `package:app_forge/engine/engine.dart`다.
- 2026-03-23: Phase 1에서는 placeholder bootstrap과 placeholder page만 두고 Router 구현은 이후 단계로 미룬다.

- 2026-03-26: Phase 2에서는 `RouteDef`, `RouterEngine`, `NavigationState`, `EngineShell`, `FeatureShell`을 최소 범위로 도입한다.
- 2026-03-26: Route path의 source of truth는 child route를 포함해 항상 절대경로로 유지한다.
- 2026-03-26: nested 표현은 `children`만 사용하고 `parent`는 도입하지 않는다.
- 2026-03-26: `RouteDef.builder`는 `(BuildContext, GoRouterState)` 시그니처를 사용한다.
- 2026-03-26: shell 포함 여부는 추론 규칙이 아니라 `useShell` metadata로 결정한다.
- 2026-03-26: `useShell` 기본값은 true로 두고 예외 화면만 shell 밖으로 뺀다.
- 2026-03-26: shell 내부 route는 `showAppBar`, `showBottomNav`, `showDrawer` metadata로 공통 UI 노출을 제어한다.
- 2026-03-26: NavigationState는 `location`, `currentRoute`, `pathParams`, `queryParams`, `extra`만 가지는 원시 상태로 유지한다.
- 2026-03-26: `appRouteTrees`와 `appRoutes`를 분리해 tree 구성과 matcher/currentRoute 판별 책임을 구분한다.
- 2026-03-26: `EngineFeature`를 최종 용어로 사용하고 `FeatureEntry`는 설계 논의 표현으로만 남긴다.
- 2026-03-26: NavigationState 갱신은 RouterEngine의 단일 sync 지점이 소유한다.
- 2026-03-26: Navigation sync는 microtask, post-frame 우회가 아니라 observer 기반 단일 흐름으로 정리한다.
- 2026-03-26: placeholder shell은 실제 EngineShell 도입 이후 제거한다.
- 2026-03-26: Phase 2에서는 Firebase, auth redirect, Result/AppError 본구현을 의도적으로 제외한다.

- 2026-03-27: Phase 3에서는 `Firebase.initializeApp()` bootstrap을 app plugin에서 수행한다.
- 2026-03-27: auth redirect는 app layer 함수로 정의하고 RouterEngine에는 `redirect`와 `refreshListenable`만 주입한다.
- 2026-03-27: auth session은 `FirebaseUser`가 아니라 `AuthSession` provider로만 외부에 노출한다.
- 2026-03-27: login 성공 정의는 `FirebaseAuth 성공 + users/{uid} upsert 성공`이다.
- 2026-03-27: `users/{uid}` upsert는 repository 내부에서만 호출하고 `DocumentReference.get() -> set/update` 방식으로 고정한다.
- 2026-03-27: users upsert 실패 시 repository 내부에서 rollback signOut을 시도하고 실패 여부와 무관하게 login은 실패로 닫는다.
- 2026-03-27: `AppError`, `Result<T>`, logger는 auth slice 내부의 임시 generic core로 구현하고 shared core로 간주하지 않는다.