# Architecture

## 목적

이 Template은 재사용 가능한 Engine 인프라와
app 조립 코드, Feature 구현 코드를 분리하기 위해 설계되었다.

구조의 핵심 경계는 다음과 같다.

구현 규칙은 `docs/02_CODING_CONTRACT.md`에서 정의하며,
세부 정책(특히 에러 처리)은 `docs/07_ERROR_POLICY.md`를 따른다.

- `lib/engine/`는 재사용 가능한 Engine layer를 가진다.
- `lib/app/`은 이 앱의 composition root를 가진다.
- `lib/features/`는 제품 기능을 vertical slice 단위로 가진다.

## 최종 트리

```text
lib/
  main.dart
  bootstrap/
    bootstrap.dart
    bootstrap_runtime.dart
  engine/
    engine.dart
    src/
      error/
      plugins/
      routing/
      shell/
  app/
    app_config.dart
    app_plugins.dart
    app_features.dart
  features/
    auth/
      domain/
      data/
      state/
    auth_entry/
      ui/
      state/
    home/
      ui/
    profile/
      ui/
    posts/
      ui/
    settings/
      ui/
  ui_kit/
```

## 폴더 책임

- `lib/engine/`: 재사용 가능한 Engine surface와 내부 구현을 가진다.
- `lib/bootstrap/`: runtime bootstrap host를 가진다. app 3파일을 소비하지만 source of truth는 아니다.
- `lib/bootstrap/bootstrap_runtime.dart`: runtime 시작에 필요한 zone, ErrorHub, plugin orchestration을 가진다.
- `lib/engine/src/error`: ErrorHub, error model, policy/logger contract를 가진다.
- `lib/engine/src/plugins`: engine이 소비하는 plugin 실행 계약을 가진다.
- `lib/engine/src/routing`: Route DSL, matcher, navigation state, RouterEngine 구현을 가진다.
- `lib/engine/src/shell`: EngineShell, FeatureShell 같은 shell UI 계약을 가진다.
- `lib/ui_kit/`: 여러 app에서 재사용 가능한 UI token과 widget을 가진다.
- `lib/app/`: 이 앱의 composition root이자 유일한 app 설정 지점을 가진다.
- `lib/features/`: vertical slice로 구성된 Feature module을 가진다.
- `lib/features/**/ui`: page, widget, layout 같은 화면 렌더링 코드를 가진다.
- `lib/features/**/state`: controller, provider, mapper, notice 같은 UI 상태와 흐름 코드를 가진다.
- `lib/features/**/domain`: 필요한 경우 Feature 계약, entity, feature-level error/result를 가진다.
- `lib/features/**/data`: 필요한 경우 repository 구현, datasource, 외부 SDK 연동을 가진다.

## app 설정 파일

app 전용 설정은 반드시 아래 3개 파일로 수렴해야 한다.

- `app_config.dart`: app의 look and feel, 초기 진입 location, 최소 shell config와 app-level policy를 정의한다.
- `app_plugins.dart`: Plugin 조립과 runtime integration을 정의한다.
- `app_features.dart`: app에 등록할 Feature 목록과 route 조립 지점을 정의한다.

이 외의 파일이 두 번째 composition root가 되면 안 된다.

`lib/bootstrap/bootstrap.dart`는 app 설정을 소비하는 runtime host일 뿐이며,
app 설정 파일 수를 늘리는 예외가 아니다.

## Import 규칙

허용:

- `lib/features/**` -> `package:app_forge/engine/engine.dart`
- `lib/app/**` -> `package:app_forge/engine/engine.dart`
- `lib/app/**` -> `lib/features/**`
- 같은 slice 내부의 `ui -> state`
- 같은 slice 내부의 `state -> data/domain`

금지:

- `lib/engine/**` -> `lib/features/**`
- `lib/engine/**` -> `lib/app/**`
- Router 코드가 auth Feature를 직접 참조하는 것
- UI widget이나 page가 Firebase SDK를 직접 호출하는 것
- layer 경계를 가로지르는 임의의 전역 singleton wiring
- `lib/app/**` 또는 `lib/features/**`가 `lib/engine/src/**`를 직접 import하는 것

## Composition 모델

- Engine은 policy, flow, abstraction, reusable widget을 가진다.
- app은 Engine, Plugin, Feature를 조립하는 composition root다.
- Feature는 제품 기능을 vertical slice 단위로 가지며, 필요한 layer만 가진다.

이 구조는 Engine의 재사용성을 유지하고, 제품 도메인 policy가 Engine 안으로 새는 것을 막는다.

## Feature 내부 구조

Feature는 UI 중심 구조를 따른다.

기존 domain/data/presentation 구조 대신, 다음 구조를 사용한다.

- `ui`: 화면 렌더링
- `state`: UI 상태 및 흐름 제어
- `data`: 외부 시스템 접근
- `domain`: 계약, entity, feature-level error/result 같은 선택 레이어

이 구조는 `presentation` 레이어에 UI와 상태가 혼합되는 문제를 방지하기 위해 도입되었다.

## Error Handling Architecture

앱의 에러 관련 흐름은 아래 두 축으로 분리한다.

### 1. Feature failure

Feature 내부 비동기 실패와 validation 실패는
`Result<T>`와 `AppError`를 사용해 처리한다.

이 축은 다음 범위를 가진다.

- validation
- repository
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

## auth / auth_entry 분리

- auth feature는 순수 기능 feature다.
- auth는 UI page를 소유하지 않는다.
- auth는 action, validation, feature-level contract를 소유한다.
- auth의 `state`는 provider/controller layer를 의미한다.
- auth는 session을 repository contract로 노출하지 않는다.
- auth_entry feature는 auth 기능을 소비만 한다.
- auth_entry feature는 login/signup/reset UI와 form controller 흐름을 소유한다.
- session 관찰은 `auth_session_provider` 경로로만 이뤄진다.
- auth_entry는 auth 계약이나 구현을 재정의하거나 복제하지 않는다.

## public Engine surface

- app과 Feature가 사용하는 유일한 public Engine import 경로는 `package:app_forge/engine/engine.dart`이다.
- `lib/engine/src/**`는 internal 구현이며 외부 계약이 아니다.