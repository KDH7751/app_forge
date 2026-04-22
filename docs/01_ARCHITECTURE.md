# Architecture

## 목적

이 문서는 현재 구조를 어떻게 읽어야 하는지 정리한다.
구현 규칙은 `docs/02_CODING_CONTRACT.md`, 에러 세부 정책은 `docs/07_ERROR_POLICY.md`를 따른다.

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
      foundation.dart
    bootstrap/
      bootstrap.dart
      bootstrap_host.dart
      bootstrap_runtime.dart
    auth/
      auth.dart
    feedback/
      feedback.dart
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

## 최상위 책임

- `lib/app/`: 이 프로젝트의 composition root이자 유일한 app 설정 지점
- `lib/engine/`: domain-agnostic infrastructure와 public Engine surface
- `lib/modules/`: 다른 프로젝트로도 거의 그대로 가져갈 수 있는 reusable module
- `lib/modules/foundation/`: modules/features가 함께 기대는 얇은 공통 기반 타입과 계약
- `lib/modules/bootstrap/`: reusable startup/composition module. app 설정을 소비하지만 source of truth는 아님
- `lib/modules/feedback/`: 3.8 잠금 범위의 app-wide feedback contract, provider/helper, root display host. 범위 밖 범용 확장을 선행하지 않는다.
- `lib/features/`: 이 프로젝트에서 실제로 소비되는 product/consumer feature
- `lib/features/common/`: project-level shared asset 위치. reusable module 위치는 아님
- `lib/ui_kit/`: 재사용 가능한 UI token과 widget

## app composition 기준

app 전용 설정은 아래 3개 파일로 수렴한다.

- `app_config.dart`: look and feel, 초기 진입 location, 최소 shell config, app-level policy
- `app_plugins.dart`: provider set과 최소 config 입력, runtime/plugin 파생값
- `app_features.dart`: feature/policy 입력, route/redirect/error wiring 파생값

이 외의 파일이 두 번째 composition root가 되면 안 된다.
bootstrap module은 runtime wiring/host일 뿐 app 설정 파일 수를 늘리는 예외가 아니다.

## Public Surface 기준

- `engine/engine.dart`는 engine의 유일한 public surface다.
- `modules/auth/auth.dart`는 auth module public surface다.
- `modules/feedback/feedback.dart`는 feedback module public surface다.
- `modules/foundation/foundation.dart`는 foundation public surface다.
- `features/common/common.dart`는 consumer-side shared surface다.
- `modules/bootstrap/bootstrap.dart`는 bootstrap module의 유일한 public entry 배럴이다.

public surface는 공개 계약과 설정 표면만 노출하고, 내부 concrete 구현은 감춘다.

## 의존 방향과 import 경계

runtime code inside `lib/`는 relative import를 기본으로 사용한다.
중요한 것은 스타일 통일보다 public surface와 internal 경계를 지키는 것이다.

허용:

- `lib/modules/**` -> `lib/engine/engine.dart`
- `lib/features/**` -> `lib/engine/engine.dart`
- `lib/features/**` -> `lib/modules/**`의 공개 표면
- `lib/features/**` -> `lib/features/common/**`
- `lib/app/**` -> `lib/engine/engine.dart`
- `lib/app/**` -> `lib/modules/**`의 공개 표면
- `lib/app/**` -> `lib/features/**`

금지:

- `lib/engine/**` -> `lib/modules/**`, `lib/features/**`, `lib/app/**`
- `lib/modules/**` -> `lib/features/**`, `lib/features/common/**`
- `lib/features/**`가 module concrete/internal 구현을 직접 참조하는 것
- `lib/app/**`가 module concrete action, endpoint, parser, provider-specific detail을 직접 소유하거나 해석하는 것
- `lib/app/**`, `lib/modules/**`, `lib/features/**`가 `lib/engine/src/**`를 직접 import하는 것

## Composition 모델

- Engine은 domain-agnostic infrastructure를 가진다.
- module은 재사용 가능한 domain-aware contract와 concrete 구현을 가진다.
- feature는 module public surface를 소비하는 project-specific UI/flow/product slice를 가진다.
- app은 module selection/config/policy와 feature exposure를 조립한다.

현재 app composition 입력 모델은 아래를 유지한다.

- 1차 provider 선택 축은 `auth`, `domain data`, `file/storage`, `analytics/crash`
- `push/notification`은 현재 범위에 포함하지 않음
- `auth`와 `domain data`는 둘 다 Firebase를 써도 같은 축으로 합치지 않음
- app은 `provider set`, `최소 config`, app 수준 `정책 입력`까지만 가짐
- 개별 action endpoint, concrete 구현, runtime wiring 세부는 app이 직접 소유하지 않음

## Module / Feature 내부 구조

reusable module과 consumer feature는 모두 UI 중심 내부 구조를 사용할 수 있다.

```text
unit/
  ui/
  state/
  data/
  domain/   # 필요 시에만
```

- `ui`: 화면 렌더링
- `state`: UI 상태와 흐름 제어
- `data`: 외부 시스템 접근
- `domain`: 공개 계약, entity, validation helper 같은 선택 레이어

`presentation` 레이어는 사용하지 않는다.
`core` 같은 포괄 명칭도 최상위 `modules`와 의미가 겹치므로 유지하지 않는다.

## 에러와 세션 경계

- feature failure는 `Result<T>` / `AppFailure`로 처리한다.
- app-wide feedback은 `FeedbackRequest`와 feedback dispatcher 흐름으로 처리한다.
- global/runtime error는 `ErrorHub` / `ErrorPolicy` / `ErrorDecision`으로 처리한다.
- engine은 에러를 해석하지 않고 전달만 한다.
- 전역 error listener는 app root에서 한 번만 등록한다.
- root host 수준에서 표시 인프라 일부를 공유할 수 있어도 feedback과 ErrorHub의 모델/정책/입력 경로는 분리한다.
- auth feature의 공식 root feedback 소비 패턴은 `AuthFailurePresenter -> AuthFeedbackCoordinator -> feedback dispatch`다.
- `AuthFeedbackCoordinator`는 auth 문맥의 request 조립과 dispatch orchestration만 맡고, local-only UI/state 전반을 흡수하지 않는다.
- `snackbar`와 `banner`는 root overlay presenter로 표시하고, `dialog`와 `modalSheet`는 feedback host의 navigator/context 경로를 유지한다.

auth/session 관련 구조 읽기 기준:

- `auth`는 reusable auth module이다.
- `bootstrap`은 reusable startup/composition module이며 observation, refreshListenable, forced logout orchestration, plugin/runtime 시작 연결 같은 runtime wiring만 담당한다.
- session invalid/forced logout 계열 root feedback dispatch도 bootstrap wiring에서만 연결한다.
- `auth_flow`는 auth module public surface를 소비하는 consumer feature다.
- session 관찰은 `auth_session_provider` 경로로만 이뤄진다.
- public `AuthSession` 최상위 상태는 `Authenticated`, `Unauthenticated`, `Invalid`, `Pending`이다.
- invalid session 해석은 auth provider/session 계열이 수행하고 redirect 판단은 계속 app layer가 가진다.

세부 정책과 phase별 잠금 내용은 `docs/04_DECISIONS.md`를 따른다.
