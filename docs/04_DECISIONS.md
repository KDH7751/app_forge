# Decisions

## Phase 1 structure and public surface foundation

Phase 1은 구조 경계와 public API 기준을 초기 고정한 단계다.

- 2026-03-23: Engine은 policy, flow, abstraction을 소유하고 concrete 구현은 app이 주입한다.
- 2026-03-23: app은 composition root다.
- 2026-03-23: Feature는 `ui/state/data/domain`을 필요에 따라 가지는 vertical slice로 유지한다.
- 2026-03-23: engine public surface는 `lib/engine/engine.dart` 하나로 유지한다.

## Phase 2 routing, shell, and navigation foundation

Phase 2는 routing engine과 shell/navigation 기반을 고정한 단계다.

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

## Phase 3.1 auth entry and auth_flow baseline

Phase 3.1은 public auth entry와 project-level auth consumer flow의 기초를 확보한 단계다.

- 2026-03-31: login/signup/reset-password 진입 흐름은 auth module을 직접 구현하는 UI가 아니라 consumer feature가 auth 공개 표면을 소비하는 구조로 유지한다.
- 2026-03-31: public auth entry route는 shell 밖에서 동작하도록 `useShell: false` 기준을 유지한다.
- 2026-04-15: 현재 이름은 `auth_flow`이며, `auth_flow`는 auth module public surface를 소비하는 project-level consumer feature다.

## Phase 3.2 global error handling

Phase 3.2는 ErrorHub 기반 global/runtime error 처리 축을 고정한 단계다.

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
- 2026-04-09: delete 확인 dialog는 현재 profile 소비 UI가 auth destructive confirm feedback request를 트리거하는 방식으로 열고, 실제 action 실행 소유권은 auth에 둔다.
- 2026-04-09: changePassword 성공 시 controller state는 `isSuccess`를 유지하되 입력값과 field error를 함께 초기화한다.
- 2026-04-09: auth flow와 profile UI의 루트 알림 보고 분기는 feature-local helper로만 정리하고, 전역 notify 정책으로 승격하지 않는다.
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

Phase 3.6은 두 축으로 읽는다.

- provider-set composition 고정
- `modules/auth`, `modules/bootstrap`, `modules/foundation`, `features/auth_flow` 재배치

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

## Phase 3.7 feature failure contract baseline

- 2026-04-20: feature-level failure 공통 계약은 계속 `Result<T>` / `AppFailure`로 유지한다.
- 2026-04-20: `AppFailureType`은 `validation`, `invalidCredentials`, `unauthorized`, `permissionDenied`, `notFound`, `conflict`, `rateLimited`, `network`, `unavailable`, `unknown`만 사용한다.
- 2026-04-20: `AppFailureType` 이름은 provider나 backend 구현을 직접 암시하지 않는다.
- 2026-04-20: `AppFailure` public contract는 `type`과 validation용 `fieldErrors`만 가진다.
- 2026-04-20: validation failure는 별도 예외 계약으로 빼지 않고 `AppFailureType.validation + fieldErrors` 구조로 수렴한다.
- 2026-04-20: raw provider code, provider exception class, backend status, provider 원문 메시지는 repository/data boundary에서만 해석하고 state/UI까지 직접 올리지 않는다.
- 2026-04-20: controller는 정규화된 `AppFailure`만 소비한다.
- 2026-04-20: UI는 `AppFailure` 공용 의미만 기준으로 상태와 문구를 결정한다.
- 2026-04-20: feature-level failure 소비 기본 패턴은 feature별 failure presenter로 유지하고, 문구 변환과 로컬 처리/공용 피드백 후보 판단은 presenter로 응집한다.
- 2026-04-20: auth는 첫 적용 대상이지만 `AppFailure` 모델과 타입 집합은 auth 전용으로 잠그지 않는다.
- 2026-04-20: auth action failure contract의 `unauthorized`와 Phase 3.5 session invalid public contract의 `InvalidReason.disabled`는 같은 raw provider 사실과 닿아도 서로 다른 계약으로 유지한다.
- 2026-04-20: 같은 raw provider code라도 action context가 다르면 서로 다른 `AppFailureType`으로 정규화될 수 있으며, `user-not-found`는 login에서 `invalidCredentials`, reset에서 `notFound`로 유지한다.
- 2026-04-20: global/runtime error 축(`ErrorHub`, `ErrorPolicy`, `ErrorDecision`)은 이번 단계에서 변경하지 않는다.

## Phase 3.8 app-wide feedback system

Phase 3.8은 현재 완료된 app-wide feedback system 단계다.

- 2026-04-21: app-wide user feedback system은 `snackbar`, `dialog`, `banner`, `modalSheet` 4개 공식 channel만 지원한다.
- 2026-04-21: popup, full-screen notice channel은 추가하지 않는다.
- 2026-04-21: 3.8 feedback system은 `modules/feedback` reusable module로 두고, 이번 phase 잠금 범위를 구현하기 위한 contract/provider/helper/root host까지만 포함한다.
- 2026-04-21: bootstrap은 host/runtime wiring만 담당하며 app 설정 source of truth를 늘리거나 대체하지 않는다.
- 2026-04-21: feature failure root notify 경로는 `ErrorHub -> root string mapper`가 아니라 `AuthFailurePresenter -> AuthFeedbackCoordinator -> feedback dispatch` 경로로 치환한다.
- 2026-04-21: feature failure 해석 책임은 presenter/coordinator 쪽에 두고 feedback 중앙 계층은 표시 실행, queue, dedupe, priority, lifecycle만 담당한다.
- 2026-04-21: `FeedbackRequest`는 `AppFailure`를 대체하지 않는다.
- 2026-04-21: auth action failure request 조립과 dispatch orchestration은 `AuthFeedbackCoordinator`가 맡고, session invalid/forced logout 계열 root feedback dispatch는 bootstrap/runtime wiring에서 연결한다.
- 2026-04-21: ErrorHub와 feedback은 root host 수준에서 표시 인프라 일부를 공유할 수 있어도 모델/정책/입력 경로는 분리 유지한다.
- 2026-04-21: semantic preset 기본 목록은 `error`, `success`, `warning`, `info`, `confirm`, `destructiveConfirm`, `sessionExpired`로 고정한다.
- 2026-04-21: 채널별 slot 공식 목록은 `snackbar(icon,title,message,action)`, `dialog(icon,title,body,actions,supplementary)`, `banner(icon,message,secondaryAction)`, `modalSheet(header,body,actions)`로 고정한다.
- 2026-04-21: slot 값이 없으면 해당 영역은 렌더링하지 않고 placeholder나 죽은 spacing을 남기지 않는다.
- 2026-04-21: override는 등록된 contract 안에서만 허용하고 자유 widget tree, 자유 render payload, animation 구현체 직접 주입은 허용하지 않는다.
- 2026-04-21: dialog와 modalSheet는 blocking 계열로 보고 동시 1개만 활성화한다.
- 2026-04-21: snackbar는 독립 채널이지만 blocking 계열이 떠 있으면 대기시킬 수 있고, banner는 동시 표시를 허용한다.
- 2026-04-21: 같은 channel 내 active request는 기본 1개이며, 더 높은 priority의 blocking request는 낮은 priority blocking request를 대체할 수 있다.
- 2026-04-21: 같은 `dedupeKey`를 가진 request가 active 상태거나 queue에 있으면 중복 생성하지 않는다.
- 2026-04-21: action 실행 시 기본 동작은 dismiss이고 필요한 경우에만 등록된 contract 안에서 override를 허용한다.
- 2026-04-21: `snackbar`와 `banner`는 custom root overlay presenter 경로로 표시하고, `dialog`와 `modalSheet`는 feedback host의 navigator/context 경로를 유지한다.
- 2026-04-21: channel별 허용 범위를 벗어나는 `position`, `layoutMode`, `animation` 조합은 request 생성 단계에서 각 channel 기본값 또는 고정값으로 안전하게 정규화한다.
- 2026-04-22: delete account confirm dialog는 auth feature의 destructive confirm feedback request로 보고, 현재 비밀번호 입력과 명시적 확인을 함께 소유할 수 있다.
- 2026-04-22: delete confirm action 이후 실제 delete submit orchestration은 `AuthFeedbackCoordinator`가 담당할 수 있다.
- 2026-04-22: delete confirm에서 나온 local-only failure는 root feedback으로 승격하지 않고 dialog/local 경로에 남긴다.

## Phase 3.6 follow-up API-style auth provider portability validation

Phase 3.6 후속 작업은 운영 API 서버 구현이 아니라 Phase 3.6 provider-set composition이
Firebase가 아닌 API-style provider 경로에서도 교체 가능하게 동작하는지 검증한 단계다.

- 2026-04-27: auth provider set 선택은 계속 `app_plugins.dart`의 `authProvider`와 `authConfig`에서 시작한다.
- 2026-04-27: API-style auth provider set은 `ApiAuthClient` contract만 소비하며, in-memory API harness server의 map/state를 직접 참조하지 않는다.
- 2026-04-27: Phase 3.6 후속 작업의 `InMemoryApiAuthClient`는 검증용 구현체이며, 향후 `HttpApiAuthClient` 같은 실제 HTTP client가 같은 `ApiAuthClient` contract 뒤에 연결되는 구조로 둔다.
- 2026-04-27: in-memory API harness는 `status`, `body`, `code`가 있는 API-style response를 제공하고, auth data/provider boundary가 이를 `Result<T>`, `AppFailure`, `AuthSession`으로 정규화한다.
- 2026-04-27: API raw status/code/body와 access token은 controller, UI, public session contract로 올리지 않는다.
- 2026-04-27: API 경로에서도 `AuthSession` public contract는 `Authenticated(uid,email)`, `Unauthenticated`, `Invalid(reason)`, `Pending`만 유지한다.
- 2026-04-27: API 경로에서도 `AppFailureType` 공식 범위는 확장하지 않고 기존 타입으로 정규화한다.
- 2026-04-27: blocked/disabled/missing account는 API account-state response에서 기존 internal invalidation fact로 수렴한 뒤 public `InvalidReason`으로 매핑한다.
- 2026-04-27: `changePassword`와 `deleteAccount`도 API test harness provider set에서 지원하며, delete 성공 의미는 auth provider account delete와 users-equivalent delete가 모두 성공한 경우로 유지한다.
- 2026-04-27: auth_flow 로그인 화면은 선택된 provider label을 표시할 수 있지만, Firebase/API concrete 구현을 import하거나 type check하지 않는다.
- 2026-04-27: app이 알아야 하는 입력은 provider 선택, provider set 최소 config, 검증용 label 후보까지로 제한하고 endpoint, parser, status mapping, concrete action/client/server state는 auth module 내부 concrete로 남긴다.
- 2026-04-27: Phase 3.6 후속 작업 검증 결과 `flutter analyze`와 `flutter test`가 통과했다.
