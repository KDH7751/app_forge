# Decisions

## Phase 1 foundation

- 2026-03-23: Engine은 policy, flow, abstraction을 소유하고 concrete 구현은 app이 주입한다.
- 2026-03-23: app은 composition root다.
- 2026-03-23: Feature는 `ui/state/data/domain`을 필요에 따라 가지는 vertical slice로 유지한다.
- 2026-03-23: engine public surface는 `lib/engine/engine.dart` 하나로 유지한다.

## Phase 2 routing foundation

- 2026-03-26: `RouteDef`, `RouterEngine`, `NavigationState`, `EngineShell`, `FeatureShell`을 최소 범위로 도입한다.
- 2026-03-26: route path source of truth는 top-level과 child 모두 절대경로로 유지한다.
- 2026-03-26: nested 표현은 `children`만 사용하고 `parent`는 도입하지 않는다.
- 2026-03-26: `RouteDef.builder`는 `(BuildContext, GoRouterState)` 시그니처를 사용한다.
- 2026-03-26: shell 포함 여부는 `useShell` metadata로 결정하고 기본값은 true로 둔다.
- 2026-03-26: shell 내부 route 공통 UI 노출은 `showAppBar`, `showBottomNav`, `showDrawer` metadata로 제어한다.
- 2026-03-26: NavigationState는 `location`, `currentRoute`, `pathParams`, `queryParams`, `extra`만 가진다.
- 2026-03-26: `appRouteTrees`와 `appRoutes`를 분리한다.
- 2026-03-26: Navigation sync는 observer 기반 단일 흐름으로 유지한다.

## Phase 3 auth/bootstrap foundation

- 2026-03-27: `Firebase.initializeApp()` bootstrap은 app plugin에서 수행한다.
- 2026-03-27: auth redirect는 app layer 함수로 정의하고 RouterEngine에는 `redirect`와 `refreshListenable`만 주입한다.
- 2026-03-27: auth session은 `FirebaseUser`가 아니라 `AuthSession` contract로만 외부에 노출한다.
- 2026-03-27: login 성공 정의는 `FirebaseAuth 성공 + users/{uid} upsert 성공`이다.
- 2026-03-27: `users/{uid}` upsert는 auth login/signup 실행 흐름 내부에서만 수행하고 `DocumentReference.get() -> set/update` 방식으로 고정한다.
- 2026-03-27: upsert 실패 시 rollback signOut을 시도하고 login/signup은 failure로 닫는다.
- 2026-03-27: bootstrap module public entry는 `lib/modules/bootstrap/bootstrap.dart` 하나로 두고, host/root 구현은 `bootstrap_host.dart`, runtime wiring은 `bootstrap_runtime.dart`로 분리한다.
- 2026-03-27: app 설정 source of truth는 `app_config.dart`, `app_plugins.dart`, `app_features.dart` 3파일로 유지한다.
- 2026-03-27: auth feature는 UI page를 소유하지 않고, login page는 별도 consumer feature가 auth를 소비한다.

## Phase 3.2 global error handling

- 2026-04-03: ErrorHub를 도입하고 모든 에러를 ErrorEnvelope로 래핑한다.
- 2026-04-03: ErrorPolicy는 ErrorEnvelope를 ErrorDecision으로 변환한다.
- 2026-04-03: ErrorDecision은 `shouldLog`, `shouldNotify`, `severity`를 가진다.
- 2026-04-03: severity는 `info`, `warning`, `error`, `fatal`로 정의하고 `isFatal`은 사용하지 않는다.
- 2026-04-03: engine은 에러를 해석하지 않고 전달만 한다.
- 2026-04-03: `domainError`는 optional metadata로만 전달되고 ErrorPolicy는 이를 타입/의미 수준에서 해석하지 않는다.
- 2026-04-03: UI는 `ErrorDecision.shouldNotify`만 기준으로 반응하고, 전역 에러 UI는 root 단일 listener에서 처리한다.
- 2026-04-03: 앱은 runZonedGuarded 기반 단일 zone에서 실행하고 `main.dart`는 runtime entry만 담당한다.
- 2026-04-03: `AppFailure`는 feature failure contract로 유지하고 global error model로 승격하지 않는다.

## Phase 3.3 post-login account actions

- 2026-04-09: `changePassword`, `deleteAccount`는 auth module이 action, validation, execution flow를 소유하고 profile feature는 임시 소비 UI만 가진다.
- 2026-04-09: `changePassword` 입력은 `currentPassword`, `newPassword`, `confirmNewPassword`로 고정한다.
- 2026-04-09: `deleteAccount` 입력은 reauthenticate용 `currentPassword`로 고정한다.
- 2026-04-09: `deleteAccount` 성공 정의는 auth provider 계정 삭제 성공 + `users/{uid}` 삭제 성공이다.
- 2026-04-09: `deleteAccount` 실행 순서는 reauthenticate -> auth provider account delete -> `users/{uid}` delete 로 고정한다.
- 2026-04-09: auth provider 계정 삭제 성공 후 `users/{uid}` 삭제 실패 시 같은 실행 흐름 안에서 최대 5회 cleanup 재시도한다.
- 2026-04-09: delete cleanup 실패가 남아 있으면 success로 승격하지 않는다.
- 2026-04-09: delete 확인 dialog는 profile UI에 두되 실제 action 실행 소유권은 auth에 둔다.
- 2026-04-09: changePassword 성공 시 controller state는 `isSuccess`를 유지하되 입력값과 field error를 함께 초기화한다.
- 2026-04-09: auth_entry와 profile UI의 루트 알림 보고 분기는 feature-local helper로만 정리하고, 전역 notify 정책으로 승격하지 않는다.
- 2026-04-09: 실제 계정 삭제 성공 의미는 계속 `auth provider delete + users/{uid} delete` 정의에만 있다.

## Phase 3.4 session integrity

- 2026-04-09: Session Integrity를 위해 서버 계정 부재와 서버 차단/비활성을 invalid session으로 해석한다.
- 2026-04-09: 계정 삭제, 차단, 비활성은 같은 invalid 축에 두되 내부 사유는 구분할 수 있게 유지한다.
- 2026-04-09: invalid 감지 시 보호 라우트는 즉시 public auth entry로 이탈시키고, 강제 logout은 그 직후 auth 흐름에서 수행한다.
- 2026-04-09: 보호 라우트 이탈은 signOut 완료를 기다리지 않는다.
- 2026-04-09: session 관찰은 계속 `auth_session_provider` 단일 경로로 유지한다.
- 2026-04-09: `users/{uid}` 문서 존재 여부와 서버 상태값(`blocked`, `disabled`)은 raw fact로만 관찰하고 invalid 해석은 provider/session 계열에서 수행한다.
- 2026-04-09: redirect 판단 책임은 계속 app layer가 가지고, bootstrap은 observation 구독, `refreshListenable` 갱신, forced logout 연결 같은 runtime wiring만 담당한다.
- 2026-04-09: Firestore 문서 기반 invalidation 외에 auth provider server-side delete/disable도 감지 대상으로 포함한다.
- 2026-04-09: auth provider server-side delete/disable 감지는 `currentUser.reload()` probe를 사용한 polling 방식으로 구현하고 기본 probe interval은 `30초`로 둔다.
- 2026-04-09: 위 polling은 최소 보수 구현이며, 즉시 push형 반영이 아니므로 최대 probe interval만큼 감지 지연이 생길 수 있다.
- 2026-04-09: login/signup 직후 첫 `users/{uid}` 스냅샷 전에는 보호 라우트를 잘못 허용하지 않도록 pending 구간을 두고 blank UI가 아니라 최소 placeholder로 처리한다.
- 2026-04-09: recovery in-flight 동안에는 `missingUserDocument` invalidation만 일시 보류해 첫 login/signup 안에서 문서 복구와 정상 진입이 함께 닫히게 한다.
- 2026-04-09: Firestore `users/{uid}` 문서 삭제로 인한 invalid + logout은 세션 무효화 대응이지 실제 계정 삭제 성공 의미가 아니다.
- 2026-04-09: 실제 계정 삭제 성공 의미는 계속 Phase 3.3의 `auth provider delete + users/{uid} delete` 정의에만 있다.

## Phase 3.5 auth session contract stabilization

- 2026-04-09: 외부 노출 session public contract 최상위 이름은 계속 `AuthSession`으로 유지한다.
- 2026-04-09: `AuthSession` public contract는 상태별 타입 분리 구조로 고정하고 enum + nullable payload 묶음 방식으로 되돌리지 않는다.
- 2026-04-09: public 최상위 상태는 `Authenticated`, `Unauthenticated`, `Invalid`, `Pending`으로 고정한다.
- 2026-04-09: `unknown`은 public contract에서 제거하고 `Pending`으로 흡수한다.
- 2026-04-09: `recovery`는 최상위 public 상태가 아니라 internal 처리 상태로 유지한다.
- 2026-04-09: 첫 `users/{uid}` 판정 전, auth provider probe 판정 전, recovery in-flight로 인해 `missingUserDocument` 판정이 일시 보류된 상태는 모두 public contract에서 `Pending`으로 수렴한다.
- 2026-04-09: redirect는 internal flag를 직접 보지 않고 최종 `AuthSession` 상태만 소비한다.
- 2026-04-09: `Authenticated`는 보호 라우트를 허용하고, `Unauthenticated`는 public auth entry로 보낸다.
- 2026-04-09: `Invalid`는 public auth entry로 이탈시키고 강제 logout 흐름과 연결한다.
- 2026-04-09: `Pending`은 placeholder 대기 상태로 두고 목적지 확정을 보류한다.
- 2026-04-09: observation `AsyncError`는 `Unauthenticated`로 강등하지 않고 `Pending`으로 유지한다.
- 2026-04-09: public invalid reason 타입 이름은 `InvalidReason`으로 고정하고 값은 `missingAccount`, `blocked`, `disabled`만 사용한다.
- 2026-04-09: internal raw invalidation reason은 `missingUserDocument -> missingAccount`, `missingAuthProviderUser -> missingAccount`, `blockedUser -> blocked`, `disabledUser -> disabled`, `disabledAuthProviderUser -> disabled`로 public reason에 매핑한다.
- 2026-04-09: `Authenticated` payload는 `uid`, `email`만 가진다.
- 2026-04-09: `Unauthenticated`와 `Pending`은 추가 payload를 가지지 않는다.
- 2026-04-09: `Invalid`는 public `reason`만 가지며 `uid`, `email`은 노출하지 않는다.
- 2026-04-09: profile/domain 성격 데이터와 internal polling/recovery 세부는 public `AuthSession` contract에 올리지 않는다.

## Phase 3.6 provider-set composition and structure lock

- 2026-04-13: `/app`의 1차 provider 선택 축은 `auth`, `domain data`, `file/storage`, `analytics/crash`다.
- 2026-04-13: `push/notification`은 범위에서 제외한다.
- 2026-04-13: `auth`와 `domain data`는 둘 다 Firebase를 써도 별개 provider 축으로 유지한다.
- 2026-04-13: app은 각 축에 대해 `provider set`, `최소 config`, app 수준 `정책 입력`까지만 가진다.
- 2026-04-13: app은 개별 action endpoint, concrete 구현 클래스, provider/runtime wiring 세부를 직접 소유하지 않는다.
- 2026-04-13: auth는 기능별 자유 혼합이 아니라 provider set 단위로 움직인다.
- 2026-04-13: auth capability는 선택된 provider set의 속성이고 app은 지원 capability를 일부 비활성화만 할 수 있다.
- 2026-04-13: auth 공통 실행 표면은 `AuthFacade`, 기능별 실행 계약 명명은 `...Action`으로 통일한다.
- 2026-04-13: auth 내부 조립 경로는 `provider set assembly -> action provider -> facade provider`를 사용한다.
- 2026-04-13: session은 facade/action assembly와 분리된 고정 축으로 유지한다.
- 2026-04-13: `app_plugins.dart`는 상단 입력 / 하단 plugin-runtime 파생 구조를 유지한다.
- 2026-04-13: `app_features.dart`는 상단 입력 / 하단 route-redirect-error wiring 파생 구조를 유지한다.
- 2026-04-14: `lib` 최상위 분류는 `app`, `engine`, `modules`, `features` 기준으로 읽는다.
- 2026-04-14: `app`은 reusable module이 아니라 composition root다.
- 2026-04-14: `engine`은 domain-agnostic infrastructure만 가진다.
- 2026-04-14: `modules`는 reusable base module이고 project-specific UI/flow 소비 로직은 가지지 않는다.
- 2026-04-14: `features`는 project-specific flow, UX, entry, product slice를 가진다.
- 2026-04-14: `features/common`은 project-level shared asset 위치이며 reusable module이나 misc/shared 창고로 사용하지 않는다.
- 2026-04-14: `modules/foundation`은 engine이 아닌 공통 기반 타입/계약 위치이며 `AppFailure`, `Result`를 둔다.
- 2026-04-14: auth 밖 공통 성격은 `modules/foundation`으로 올리고 auth 내부에는 auth-local 이름만 남긴다.
- 2026-04-14: `auth_flow`는 auth module public surface를 소비하는 project-level auth consumer feature로 유지한다.
- 2026-04-14: `bootstrap`은 reusable startup/composition module로 유지하고 redirect policy 소유권은 app layer에 남긴다.
- 2026-04-14: modules는 `engine`에 의존할 수 있지만 `features`나 `features/common`의 소비 구현에 의존하면 안 된다.
- 2026-04-14: features는 modules public surface를 소비할 수 있지만 concrete 구현 세부에 직접 의존하면 안 된다.
- 2026-04-14: runtime code inside `lib/`는 relative import를 기본으로 사용한다.
- 2026-04-14: `lib/app/**`, `lib/modules/**`, `lib/features/**`는 `lib/engine/src/**`를 직접 import하지 않는다.
