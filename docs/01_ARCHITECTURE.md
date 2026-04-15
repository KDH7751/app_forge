# Architecture

## 목적

이 Template은 domain-agnostic Engine 인프라,
재사용 가능한 기본 module,
이 프로젝트의 consumer feature,
그리고 app 조립 코드를 분리하기 위해 설계되었다.

구조의 핵심 경계는 다음과 같다.

구현 규칙은 `docs/02_CODING_CONTRACT.md`에서 정의하며,
세부 정책(특히 에러 처리)은 `docs/07_ERROR_POLICY.md`를 따른다.

- `lib/engine/`는 domain-agnostic infrastructure를 가진다.
- `lib/modules/`는 다른 프로젝트로도 거의 그대로 들고 갈 수 있는 reusable module을 가진다.
- `lib/features/`는 이 프로젝트에서 실제로 소비되는 consumer feature를 가진다.
- `lib/app/`은 이 프로젝트의 composition root를 가진다.

## 현재 실제 최상위 구조

```text
lib/
  app/
    app_config.dart
    app_plugins.dart
    app_features.dart
  engine/
    engine.dart
    src/
      error/
      plugins/
      routing/
      shell/
  modules/
    foundation/
      app_error.dart
      result.dart
      foundation.dart
    bootstrap/
    auth/
      auth.dart
  features/
    common/
      common.dart
    auth_flow/
      auth_flow.dart
    home/
      ui/
    posts/
      ui/
    profile/
      ui/
    settings/
      ui/
  ui_kit/
```

## 폴더 책임

- `lib/app/`: 이 프로젝트의 composition root이자 유일한 app 설정 지점을 가진다.
- `lib/engine/`: domain-agnostic Engine surface와 내부 구현을 가진다.
- `lib/engine/src/error`: ErrorHub, error model, policy/logger contract를 가진다.
- `lib/engine/src/plugins`: engine이 소비하는 plugin 실행 계약을 가진다.
- `lib/engine/src/routing`: Route DSL, matcher, navigation state, RouterEngine 구현을 가진다.
- `lib/engine/src/shell`: EngineShell, FeatureShell 같은 shell UI 계약을 가진다.
- `lib/modules/`: 다른 프로젝트로도 거의 그대로 가져갈 수 있는 reusable core-like module을 가진다.
- `lib/modules/foundation/`: engine은 아니지만 modules/features가 함께 기대는 얇은 공통 기반 타입과 계약을 가진다. 현재 `AppError`, `Result`가 이 위치에 있다.
- `lib/modules/bootstrap/`: reusable startup/composition module을 가진다. app 3파일을 소비하지만 source of truth는 아니다.
- `lib/modules/auth/`: reusable auth module을 가진다. auth contract, provider set, session contract, provider-specific concrete 구현을 소유한다.
- `lib/features/`: 이 프로젝트에서 실제로 소비되는 product/consumer feature를 가진다.
- `lib/features/common/`: consumer-side shared asset 위치다. 현재 실제 코드에는 `common.dart` public surface만 있고 shared asset 배치는 비어 있다.
- `lib/features/auth_flow/`: auth module의 공개 표면을 실제 앱 UX와 진입 흐름으로 소비하는 project-level auth consumer feature를 가진다. `auth_flow.dart`가 feature entry 역할을 한다.
- `lib/features/**/ui`: page, widget, layout 같은 consumer UI 렌더링 코드를 가진다.
- `lib/features/**/state`: controller, provider, mapper, notice 같은 consumer-side 상태와 흐름 코드를 가진다.
- `lib/modules/**/ui`: module이 외부에 제공하는 재사용 UI가 필요할 때만 가진다.
- `lib/modules/**/state`: module의 provider, controller, assembly, consumer-independent flow를 가진다.
- `lib/modules/**/domain`: module public contract, entity, module-level error/result 같은 계약을 가진다.
- `lib/modules/**/data`: module의 concrete action, datasource, factory, 외부 SDK 연동을 가진다.
- `lib/ui_kit/`: 여러 app에서 재사용 가능한 UI token과 widget을 가진다.

## app 설정 파일

app 전용 설정은 반드시 아래 3개 파일로 수렴해야 한다.

- `app_config.dart`: app의 look and feel, 초기 진입 location, 최소 shell config와 app-level policy를 정의한다.
- `app_plugins.dart`: 영역별 provider set, 최소 config, runtime/plugin 파생값을 정의한다.
- `app_features.dart`: feature/policy 입력과 route/redirect/error wiring 파생값을 정의한다.

이 외의 파일이 두 번째 composition root가 되면 안 된다.

bootstrap module은 app 설정을 소비하는 runtime host일 뿐이며,
app 설정 파일 수를 늘리는 예외가 아니다.

## 최상위 분류 기준

- `engine`: navigation, routing primitive, shell, notice, public Engine surface 같은 domain-agnostic infrastructure만 가진다.
- `modules`: domain을 알아도 되지만, project-specific consumer UI/flow/feature 소비 로직은 가지지 않는 reusable module이다.
- `features`: 이 프로젝트에서 실제로 소비되는 product/consumer feature다.
- `features/common`: 여러 feature가 함께 쓰는 project-level shared asset 위치다. reusable module을 두는 위치가 아니다.
- `app`: modules와 features를 실제 앱으로 선택/조립하는 composition root다.

## engine / modules / features 차이

- engine과 modules의 차이는 domain 인지 여부다. engine은 domain을 모르고, module은 domain-aware contract와 concrete 구현을 가질 수 있다.
- engine과 `modules/foundation`의 차이는 역할 범위다. engine은 runtime/routing/shell 같은 infra를 소유하고, `modules/foundation`은 modules/features가 함께 기대는 얇은 기반 타입과 계약을 소유한다.
- modules와 features의 차이는 재사용 가능성과 소비자 역할이다. module은 제공자이고, feature는 그 공개 표면을 소비하는 consumer다.
- features/common은 consumer-side shared asset 위치일 뿐 상위 core나 module 계층이 아니다.
- features/common은 현재 `common.dart` public surface만 가지며, reusable module을 대신하는 위치가 아니다.
- app은 기반 기능을 제공하는 위치가 아니라, 이 프로젝트가 어떤 module과 feature를 어떤 정책으로 사용할지 결정하는 위치다.

## Public Surface 기준

- `engine/engine.dart`는 engine의 유일한 public surface다.
- `modules/auth/auth.dart`는 auth module의 공개 계약과 설정 표면을 모으는 public surface다.
- `modules/foundation/foundation.dart`는 foundation layer가 외부에 노출할 얇은 기반 타입/계약의 public surface다.
- `features/common/common.dart`는 consumer-side shared asset의 public surface다.
- `modules/bootstrap/bootstrap.dart`는 예외적으로 별도 barrel이 아니라 기능 파일 자체가 진입점으로 유지된다.
- public surface는 소비자에게 필요한 계약과 설정 표면만 노출하고, assembly/provider-specific runtime/support/datasource 같은 내부 concrete 구현은 감춘다.

## 의존 방향과 공개 표면

허용:

- `lib/modules/**` -> `package:app_forge/engine/engine.dart`
- `lib/features/**` -> `package:app_forge/engine/engine.dart`
- `lib/features/**` -> `lib/modules/**`의 공개 표면
- `lib/features/**` -> `lib/features/common/**`
- `lib/app/**` -> `package:app_forge/engine/engine.dart`
- `lib/app/**` -> `lib/modules/**`의 공개 표면
- `lib/app/**` -> `lib/features/**`

금지:

- `lib/engine/**` -> `lib/modules/**`
- `lib/engine/**` -> `lib/features/**`
- `lib/engine/**` -> `lib/app/**`
- `lib/modules/**` -> `lib/features/**`
- `lib/modules/**` -> `lib/features/common/**`
- `lib/features/**`가 `lib/modules/**`의 concrete 구현 세부를 직접 참조하는 것
- `lib/app/**`가 module의 concrete action, endpoint, parser, provider-specific implementation detail을 직접 소유하거나 해석하는 것
- Router 코드가 auth consumer feature를 직접 참조하는 것
- UI widget이나 page가 Firebase SDK를 직접 호출하는 것
- layer 경계를 가로지르는 임의의 전역 singleton wiring
- `lib/app/**`, `lib/modules/**`, `lib/features/**`가 `lib/engine/src/**`를 직접 import하는 것

## Composition 모델

- Engine은 domain-agnostic infrastructure를 가진다.
- module은 재사용 가능한 domain-aware contract와 concrete 구현을 가진다.
- feature는 module의 공개 표면을 소비하는 project-specific UI/flow/product slice를 가진다.
- app은 module selection/config/policy와 feature exposure를 조립하는 composition root다.

이 구조는 Engine의 재사용성을 유지하고, 제품 도메인 policy가 Engine 안으로 새는 것을 막는다.
동시에 reusable module과 project-specific consumer flow가 같은 축으로 섞이지 않게 한다.

## app composition 입력 모델

- `/app`의 1차 provider 선택 축은 `auth`, `domain data`, `file/storage`, `analytics/crash`다.
- `push/notification`은 현재 phase 범위에 포함하지 않는다.
- `auth`와 `domain data`는 둘 다 Firebase를 써도 같은 축으로 합치지 않는다.
- app은 각 축에 대해 `provider set`, 그 set이 동작하기 위한 `최소 config`, app 수준 `정책 입력`까지만 가진다.
- 개별 action endpoint, concrete action 구현 클래스, runtime wiring 세부는 app이 직접 소유하지 않는다.
- `domain data`, `file/storage`, `analytics/crash`는 현재 composition 축으로 정의하는 범위까지만 잠그며, auth 외 축의 concrete provider set 예시는 실제 구현이 필요한 축에서만 확장한다.
- `push/notification`은 현재 composition 입력 모델에 포함하지 않는 것을 범위 경계로 유지한다.

현재 app 3파일의 읽기 기준은 아래와 같다.

- `app_plugins.dart` 상단: 사용자가 직접 수정하는 provider set / 최소 config 입력
- `app_plugins.dart` 하단: 입력으로부터 계산되는 plugin/runtime 파생값
- `app_features.dart` 상단: 사용자가 직접 수정하는 feature/policy 입력
- `app_features.dart` 하단: 입력으로부터 계산되는 route/redirect/error wiring 파생값

app은 reusable module이 아니며, module 내부 concrete 구현을 직접 소유하지 않는다.
app은 module이 노출한 설정 표면과 공개 계약을 통해 이 프로젝트의 사용 방식을 결정한다.

## Module / Feature 내부 구조

reusable module과 consumer feature는 모두 UI 중심 내부 구조를 사용할 수 있다.
최상위 분류는 재사용성/소비자 역할로 판단하고, 내부 layer는 책임으로 판단한다.

기존 domain/data/presentation 구조 대신, 다음 구조를 사용한다.

- `ui`: 화면 렌더링
- `state`: UI 상태 및 흐름 제어
- `data`: 외부 시스템 접근
- `domain`: 공개 계약, entity, feature-level 또는 module-level contract 같은 선택 레이어

이 구조는 `presentation` 레이어에 UI와 상태가 혼합되는 문제를 방지하기 위해 도입되었다.

module 안에서 `core` 같은 포괄 명칭은 최상위 `modules`와 의미가 겹치므로 유지하지 않는다.
auth 밖에서도 읽히는 공통 기반 타입은 현재 `modules/foundation`으로 정리했고,
auth 안에 남는 것은 auth-local 역할이 드러나는 이름으로 유지한다.

## Error Handling Architecture

앱의 에러 관련 흐름은 아래 두 축으로 분리한다.

### 1. Feature failure

Feature 내부 비동기 실패와 validation 실패는
`modules/foundation`의 `Result<T>`와 `AppError`를 사용해 처리한다.

이 축은 다음 범위를 가진다.

- validation
- action / data execution
- controller
- feature UI

`AppError`는 feature-level 실패 표현이며,
앱 전역/runtime 에러 모델이 아니다.

### 2. Global/runtime error

앱 전역 에러 처리는 `ErrorHub` 기반 중앙 처리 구조를 사용한다.

```text
[Error 발생]
  ↓
ErrorHub (engine)
  ↓
ErrorPolicy (app)
  ↓
ErrorDecision
  ↓
 ├─ Logger (app_plugins)
 └─ UI Event (stream -> root listener)
```

구조 규칙:

- engine은 에러를 전달만 하며, 그 의미를 해석하지 않는다.
- ErrorPolicy는 app layer에서 정의된다.
- UI는 ErrorDecision을 기반으로 표현만 수행한다.
- `domainError`는 단순 metadata로만 전달된다.
- ErrorPolicy는 `domainError`의 존재 여부만 사용할 수 있다.
- `domainError`의 타입, 필드, 의미를 해석하면 안 된다.

UI 규칙:

- 전역 error listener는 app root에서 단 한 번만 등록한다.
- feature 내부에서 stream을 직접 listen하지 않는다.
- feature UI는 자신의 `AppError`를 처리할 수 있다.
- app root의 전역 에러 UI는 `ErrorDecision.shouldNotify`만 기준으로 반응한다.
- 메시지 변환은 feature mapper를 사용한다.

에러 처리의 세부 정책과 규칙은 `docs/07_ERROR_POLICY.md`를 따른다.
구현 레벨에서의 규칙은 `docs/02_CODING_CONTRACT.md`를 참고한다.

## auth / bootstrap / auth_flow 해석

- auth는 일반 product feature가 아니라 reusable auth module로 읽는다.
- auth module은 `AuthFacade`, `...Action`, validation, provider set, session contract, provider-specific concrete 구현을 소유한다.
- auth module은 login/signup/logout/reset뿐 아니라 authenticated post-login action의 실행 계약과 조립을 함께 소유한다.
- auth는 기능별 자유 혼합을 기본 모델로 허용하지 않고 provider set 단위로 concrete action/session을 조립한다.
- auth capability는 선택된 auth provider set의 속성이며, app은 지원되는 capability를 일부 비활성화만 할 수 있다.
- auth 최소 config는 provider set 전체 설정 수준까지만 app이 가진다.
- auth의 `state`는 setup/runtime/action/facade/session provider와 consumer-independent controller layer를 의미한다.
- auth는 session을 facade/action contract로 노출하지 않는다.
- bootstrap은 일반 product feature가 아니라 reusable startup/composition module로 읽는다.
- bootstrap module은 session observation, refreshListenable, logout orchestration, plugin/runtime 시작 연결 같은 runtime wiring을 담당한다.
- auth_flow feature는 login/signup/reset UI와 form controller 흐름, project-level auth usage와 UX shell을 소유한다.
- auth_flow는 예전 entry screen의 이름만 바꾼 위치가 아니라, auth module의 공개 계약을 소비하는 project-level auth usage/flow/UX shell로 읽는다.
- auth_flow는 auth module의 공개 계약을 소비할 뿐 auth 계약이나 concrete 구현을 재정의하거나 복제하지 않는다.
- auth_flow의 feature entry는 `auth_flow.dart`이며, app은 이 진입점을 통해 auth_flow route와 notice surface를 읽는다.
- `authRecoveryCountProvider` 같은 session recovery tuning 값은 auth module 내부 concern으로 유지하고 auth_flow 공개 소비 계약에 올리지 않는다.
- session 관찰은 `auth_session_provider` 경로로만 이뤄진다.
- 외부 노출 session public contract 최상위 이름은 계속 `AuthSession`으로 유지한다.
- `AuthSession` public contract는 상태별 타입 분리 구조를 사용한다.
- public 최상위 상태는 `Authenticated`, `Unauthenticated`, `Invalid`, `Pending`으로 고정한다.
- `Authenticated`는 `uid`, `email`만 가진다.
- `Invalid`는 public `InvalidReason`만 가진다.
- `Unauthenticated`와 `Pending`은 추가 payload를 가지지 않는다.
- `users/{uid}` 문서 상태와 auth provider server-side delete/disable은 auth session 관찰 경로에서 raw fact로만 읽는다.
- invalid session 해석은 auth provider/session 계열이 수행하고, data/action layer는 session invalidation policy를 소유하지 않는다.

현재 auth module 내부 기본 구조는 아래처럼 이해한다.

- `domain`: `AuthFacade`, `...Action`, auth 입력 모델, validation helper, `AuthSession`, auth-local 계약
- `data`: provider set이 사용하는 concrete action, datasource, runtime factory
- `state`: setup/runtime/action/facade provider, session provider, controller

## Session Integrity 경계

- 서버 계정 부재와 서버 차단/비활성은 일반 unauthenticated가 아니라 invalid session으로 해석한다.
- 삭제/차단/비활성은 같은 invalid 축에 두되 내부 사유는 구분할 수 있다.
- invalid 감지 시 보호 라우트는 즉시 이탈시키고 강제 logout은 그 직후 auth 흐름에서 수행한다.
- 보호 라우트 이탈은 signOut 완료를 기다리지 않는다.
- session 축은 facade/action assembly의 부속물이 아니라 별도 고정 기반 축으로 유지한다.
- 첫 `users/{uid}` 판정 전, auth provider probe 판정 전, recovery in-flight 동안의 합법적 과도 상태는 public contract에서 `Pending`으로 수렴한다.
- `unknown`은 public contract에서 제거되고 `Pending`에 흡수된다.
- `recovery`는 최상위 public 상태가 아니라 internal 처리 상태로 유지한다.
- bootstrap module은 session observation, refreshListenable, logout orchestration만 담당하는 runtime wiring이다.
- redirect 판단과 진입 경로 결정은 계속 app layer가 가진다.
- Firestore `users/{uid}` 문서 삭제로 인한 invalid + logout은 세션 무효화 대응이며, 실제 계정 삭제 성공 의미는 아니다.

## post-login account action 배치

- `changePassword`, `deleteAccount`는 auth module이 action, validation, execution flow를 소유한다.
- profile feature는 Phase 3.3에서 이 기능들의 임시 소비 UI만 가진다.
- profile은 post-login account action의 state나 business logic을 소유하지 않는다.
- delete account 확인 dialog도 profile UI에 두지만, 입력 확인용 UI일 뿐 action 소유권은 auth에 남는다.

## public Engine surface

- app, modules, features가 사용하는 유일한 public Engine import 경로는 `package:app_forge/engine/engine.dart`이다.
- `lib/engine/src/**`는 internal 구현이며 외부 계약이 아니다.
