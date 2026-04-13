# Decisions

## Phase 1 foundation

- 2026-03-23: Engine은 policy, flow, abstraction을 소유하고 concrete 구현은 재사용성을 위해 app이 주입한다.
- 2026-03-23: app은 Engine, Plugin, Feature를 조립하는 composition root다.
- 2026-03-23: Feature는 ui, state, data, domain을 필요에 따라 가지는 vertical slice로 유지한다.
- 2026-03-23: app과 Feature의 유일한 public Engine import 경로는 `package:app_forge/engine/engine.dart`다.
- 2026-03-23: Phase 1에서는 placeholder bootstrap과 placeholder page만 두고 Router 구현은 이후 단계로 미룬다.

## Phase 2 routing foundation

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

## Phase 3 auth/bootstrap foundation

- 2026-03-27: Phase 3에서는 `Firebase.initializeApp()` bootstrap을 app plugin에서 수행한다.
- 2026-03-27: auth redirect는 app layer 함수로 정의하고 RouterEngine에는 `redirect`와 `refreshListenable`만 주입한다.
- 2026-03-27: auth session은 `FirebaseUser`가 아니라 `AuthSession` provider로만 외부에 노출한다.
- 2026-03-27: login 성공 정의는 `FirebaseAuth 성공 + users/{uid} upsert 성공`이다.
- 2026-03-27: `users/{uid}` upsert는 auth login/signup 실행 흐름 내부에서만 호출하고 `DocumentReference.get() -> set/update` 방식으로 고정한다.
- 2026-03-27: users upsert 실패 시 auth 실행 흐름 내부에서 rollback signOut을 시도하고 실패 여부와 무관하게 login은 실패로 닫는다.
- 2026-03-27: `AppError`, `Result<T>`, logger는 auth slice 내부의 임시 generic core로 구현하고 shared core로 간주하지 않는다.
- 2026-03-27: runtime bootstrap host는 `lib/bootstrap/bootstrap.dart`로 두고, app 설정은 계속 `app_config.dart`, `app_plugins.dart`, `app_features.dart` 3파일만 source of truth로 유지한다.
- 2026-03-27: engine 내부의 bootstrap 개념은 `plugins`로 rename하고 public engine surface는 이를 export한다.
- 2026-03-27: auth feature는 UI page를 소유하지 않고 provider/controller 같은 state layer만 가진다.
- 2026-03-27: login page는 별도 UI feature로 분리하고 auth 기능을 소비만 한다.
- 2026-03-27: feature는 필요한 layer만 가진다. `ui/state/data/domain`을 모두 강제하지 않는다.

## Phase 3.1 auth UX split

- 2026-03-31: Phase 3.1에서는 auth 기능을 login/signup/logout/reset + validation 규칙까지 확장한다.
- 2026-03-31: auth feature는 action/validation/session model을 소유하고, auth_entry feature는 login/signup/reset UI와 form controller를 소유한다.
- 2026-03-31: auth 실행/validation 공통 표면은 session stream을 노출하지 않고, session 관찰은 별도 provider 축으로 유지한다.
- 2026-03-31: auth session 관찰은 `auth_session_provider`가 FirebaseAuth 기반 별도 provider로 소유한다.
- 2026-03-31: `/login`, `/signup`, `/reset-password`는 모두 `useShell: false` standalone public route로 고정한다.
- 2026-03-31: signup 성공 정의는 `createUser + users/{uid} upsert 성공`이며, upsert 실패 시 rollback signOut을 시도하고 signup을 실패로 닫는다.
- 2026-03-31: signup의 `users/{uid}` upsert는 `DocumentReference.get() -> set/update` 방식으로만 수행하고 `createdAt`은 최초 생성 시에만 기록한다.
- 2026-03-31: validation은 auth가 `Result<void>`와 `AppError`로 정의하고, auth_entry는 표시와 navigation timing만 소유한다.
- 2026-03-31: Feature 내부 기본 구조는 `ui/state/data/domain`으로 고정하고 `presentation` 레이어는 더 이상 사용하지 않는다.

## Phase 3.2 global error handling

- 2026-04-03: Phase 3.2에서는 전역 에러 처리를 위해 ErrorHub를 도입한다.
- 2026-04-03: ErrorHub는 모든 에러를 ErrorEnvelope로 래핑한다.
- 2026-04-03: ErrorPolicy는 ErrorEnvelope를 ErrorDecision으로 변환한다.
- 2026-04-03: ErrorDecision은 `shouldLog`, `shouldNotify`, `severity`를 가진다.
- 2026-04-03: severity는 `info`, `warning`, `error`, `fatal`로 정의한다.
- 2026-04-03: `isFatal` 필드는 사용하지 않는다.
- 2026-04-03: engine은 에러를 해석하지 않고 전달만 한다.
- 2026-04-03: domainError는 optional metadata로만 전달된다.
- 2026-04-03: ErrorPolicy는 domainError 타입을 캐스팅하거나 해석하지 않는다.
- 2026-04-03: Logger는 ErrorDecision을 알지 않고 severity만 전달받는다.
- 2026-04-03: UI는 `ErrorDecision.shouldNotify`만 기준으로 반응한다.
- 2026-04-03: 전역 에러 UI 처리는 root 단일 listener에서 수행한다.
- 2026-04-03: runZonedGuarded 기반 단일 zone에서 앱을 실행한다.
- 2026-04-03: `ensureInitialized`, ErrorHub 생성, capture 설치, plugin init, `runApp`은 동일 zone에서 수행한다.
- 2026-04-03: `main.dart`는 runtime entry 역할만 수행한다.
- 2026-04-03: runtime orchestration은 bootstrap layer로 이동한다.
- 2026-04-03: ErrorEnvelope, ErrorEvent, ErrorDecision, ErrorSource는 단일 file로 통합한다.
- 2026-04-03: model 통합은 DX 개선 목적이며 책임 분리는 유지한다.
- 2026-04-03: `AppError`는 feature failure contract로 유지하고, global error model로 승격하지 않는다.

## Phase 3.3 post-login account actions

- 2026-04-09: Phase 3.3에서는 authenticated post-login account action으로 `changePassword`, `deleteAccount`를 auth feature에 추가한다.
- 2026-04-09: auth feature는 계속 UI page를 소유하지 않으며, profile feature는 이 두 action의 임시 소비 UI만 가진다.
- 2026-04-09: `changePassword` 입력은 `currentPassword`, `newPassword`, `confirmNewPassword`를 가진 input model로 고정한다.
- 2026-04-09: `deleteAccount` 입력은 reauthenticate를 위한 `currentPassword` input model로 고정한다.
- 2026-04-09: changePassword/deleteAccount validation 본체는 auth domain helper가 소유하고, data layer는 concrete SDK 호출만 수행한다.
- 2026-04-09: `deleteAccount` 성공 정의는 auth provider 계정 삭제 성공 + `users/{uid}` 삭제 성공이다.
- 2026-04-09: `deleteAccount` 실행 순서는 reauthenticate -> auth provider account delete -> `users/{uid}` delete 로 고정한다.
- 2026-04-09: auth provider 계정 삭제 성공 후 `users/{uid}` 삭제가 실패하면 auth delete 실행 흐름 내부에서 같은 문서 삭제 cleanup을 즉시 최대 5회 재시도한다.
- 2026-04-09: delete cleanup 성공 여부와 무관하게 partial delete는 success로 승격하지 않고 failure로 닫는다.
- 2026-04-09: delete 확인 dialog는 profile UI에 두되, dialog는 입력 확인만 담당하고 실제 delete action 실행은 dialog 바깥 UI가 auth controller를 통해 호출한다.
- 2026-04-09: changePassword 성공 시 controller state는 `isSuccess`를 유지하되 `currentPassword`, `newPassword`, `confirmNewPassword`와 field error를 함께 초기화한다.
- 2026-04-09: auth_entry와 profile UI의 루트 알림 보고 분기는 feature-local helper로만 정리하고, 전역 notify 정책으로 승격하지 않는다.

## Phase 3.4 session integrity

- 2026-04-09: Phase 3.4에서는 Session Integrity를 위해 서버 계정 부재와 서버 차단/비활성을 invalid session으로 해석한다.
- 2026-04-09: 계정 삭제, 차단, 비활성은 같은 invalid 축에 두되 내부 사유는 구분할 수 있게 유지한다. 단, 최종 session shape와 reason data structure는 아직 확정하지 않는다.
- 2026-04-09: invalid 감지 시 보호 라우트는 즉시 public auth entry로 이탈시키고, 강제 logout은 그 직후 auth 흐름에서 수행한다.
- 2026-04-09: 보호 라우트 이탈은 signOut 완료를 기다리지 않는다.
- 2026-04-09: session 관찰은 계속 `auth_session_provider` 단일 경로로 유지한다.
- 2026-04-09: `users/{uid}` 문서 존재 여부와 서버 상태값(`blocked`, `disabled`)은 raw fact로만 관찰하고, invalid 정책 해석은 provider/session 계열에서 수행한다.
- 2026-04-09: redirect 판단 책임은 계속 app layer가 가지며, bootstrap은 observation 구독, `refreshListenable` 갱신, forced logout 연결 같은 runtime wiring만 담당한다.
- 2026-04-09: Firestore 문서 기반 invalidation 외에 auth provider server-side delete/disable도 Phase 3.4 범위에서 감지 대상으로 포함한다.
- 2026-04-09: auth provider server-side delete/disable 감지는 `currentUser.reload()` probe를 사용한 polling 방식으로 구현하고, 기본 probe interval은 `30초`로 둔다.
- 2026-04-09: 위 polling은 3.4 범위의 최소 보수 구현이며, 즉시 push형 반영이 아니므로 최대 probe interval만큼 감지 지연이 생길 수 있다.
- 2026-04-09: login/signup 직후 첫 `users/{uid}` 스냅샷 전에는 보호 라우트를 잘못 허용하지 않도록 pending 구간을 둔다. 이 구간은 blank UI가 아니라 최소 placeholder로 처리한다.
- 2026-04-09: 위 pending/recovery 처리는 3.4 안정성 보강용이며, 최종 session contract로 승격하지 않는다.
- 2026-04-09: 기존 auth provider 계정은 살아 있고 `users/{uid}` 문서만 없는 경우, 첫 login/signup 시도 안에서 문서 복구와 정상 진입이 함께 닫히도록 `missingUserDocument` invalidation만 recovery in-flight 동안 일시 보류한다.
- 2026-04-09: Firestore `users/{uid}` 문서 삭제로 인한 invalid + logout은 세션 무효화 대응이지 실제 계정 삭제 성공 의미가 아니다.
- 2026-04-09: 실제 계정 삭제 성공 의미는 계속 Phase 3.3의 `auth provider delete + users/{uid} delete` 정의에만 있다. 따라서 Firestore 문서만 수동 삭제된 경우 재가입 불가(`emailAlreadyInUse`)는 정상 결과로 본다.

## Phase 3.5 auth session contract stabilization

- 2026-04-09: Phase 3.5에서는 외부 노출 session public contract 최상위 이름을 계속 `AuthSession`으로 유지한다.
- 2026-04-09: `AuthSession` public contract는 상태별 타입 분리 구조로 고정하고, enum + nullable payload 묶음 방식으로 되돌리지 않는다.
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
- 2026-04-09: profile/domain 성격의 데이터는 `AuthSession` public contract에 넣지 않는다.
- 2026-04-09: `userReady`, `providerReady`, `recovering`, `pendingReason`, recovery counter, polling wiring, 세부 raw invalidation reason은 internal only로 유지한다.

## Phase 3.6 provider-set composition

- 2026-04-13: Phase 3.6의 중심은 `/app`이 영역별 provider set을 선택하고, 각 영역 내부가 그 set을 concrete 구현으로 조립하는 구조다.
- 2026-04-13: `/app`의 1차 provider 선택 축은 `auth`, `domain data`, `file/storage`, `analytics/crash`다.
- 2026-04-13: `push/notification`은 이번 phase 범위에 포함하지 않고 보류한다.
- 2026-04-13: `auth`와 `domain data`는 둘 다 Firebase를 써도 항상 별개 provider 축으로 유지한다.
- 2026-04-13: app은 각 provider 축에 대해 `provider set`, 그 set이 동작하기 위한 `최소 config`, app 수준 `정책 입력`까지만 가진다.
- 2026-04-13: app은 개별 auth action endpoint, concrete action 구현 클래스, provider wiring 세부, runtime wiring 세부를 직접 소유하지 않는다.
- 2026-04-13: `domain data`, `file/storage`, `analytics/crash`는 현재 phase에서 composition 축으로 정의하는 범위까지만 잠그고, auth 외 축의 concrete provider set 예시는 실제 구현이 필요한 축에서만 확장한다.
- 2026-04-13: `push/notification`은 이번 phase의 composition 축 목록에 포함하지 않는 것을 범위 경계로 유지한다.
- 2026-04-13: auth는 기능별 자유 혼합을 기본 모델로 허용하지 않고 provider set 단위로 움직인다.
- 2026-04-13: auth capability는 기본적으로 선택된 auth provider set의 속성이다. app은 지원되지 않는 capability를 새로 만들 수 없고, 지원되는 capability를 일부 비활성화만 할 수 있다.
- 2026-04-13: auth 최소 config는 provider set 전체 설정 수준까지만 app이 가진다. action별 endpoint 같은 세부 설정은 provider set 내부 구현이 소유한다.
- 2026-04-13: auth 공통 실행 표면은 `AuthFacade`로 두고, 기능별 실행 계약 명명은 `...Action`으로 통일한다.
- 2026-04-13: auth 내부는 `provider set assembly -> action provider -> facade provider` 조립 경로를 사용한다.
- 2026-04-13: session은 facade/action assembly와 분리된 고정 기반 축으로 유지하고, public `AuthSession` contract와 redirect 소비 구조는 계속 유지한다.
- 2026-04-13: `app_plugins.dart`는 상단에 사용자가 직접 수정하는 provider set / 최소 config 입력을 두고, 하단에 그 입력으로부터 계산되는 runtime/plugin 파생값을 둔다.
- 2026-04-13: `app_features.dart`는 상단에 사용자가 직접 수정하는 feature/policy 입력을 두고, 하단에 그 입력으로부터 계산되는 route/redirect/error wiring 파생값을 둔다.
