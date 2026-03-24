# Architecture

## 목적

이 Template은 재사용 가능한 Engine 인프라와 app 조립 코드, 그리고
Feature 구현 코드를 분리하기 위해 설계되었다.

경계는 다음과 같이 엄격하게 유지한다.

- `lib/engine/`는 policy, flow, abstraction, 재사용 가능한 Engine widget을 가진다.
- `app/`은 Engine, Plugin, 등록된 Feature를 조립한다.
- `features/`는 제품 기능을 vertical slice 단위로 가진다.

## 최종 트리

```text
lib/
  main.dart
  engine/
    engine.dart
    src/
      bootstrap/
      routing/
      shell/
  app/
    app_config.dart
    app_plugins.dart
    app_features.dart
  features/
    auth/
      presentation/
    home/
      presentation/
    profile/
      presentation/
    posts/
      presentation/
  ui_kit/
```

## 폴더 책임

- `lib/engine/`: 재사용 가능한 Engine surface와 내부 Engine 구현을 가진다.
- `lib/engine/src/bootstrap`: composition root가 사용하는 app bootstrap 계약을 가진다.
- `lib/engine/src/routing`: Route DSL, matcher, navigation state, RouterEngine 구현을 가진다.
- `lib/engine/src/shell`: EngineShell과 FeatureShell 같은 재사용 가능한 shell UI 계약을 가진다.
- `lib/ui_kit/`: 여러 app에서 재사용할 수 있는 UI token과 widget을 가진다.
- `lib/app/`: 이 앱의 composition root이자 유일한 app 설정 지점을 가진다.
- `lib/features/`: vertical slice로 구성된 Feature module을 가진다.
- `lib/features/**/presentation`: Feature UI와 presentation state를 가진다.

## 3개 app 설정 파일

app 전용 설정은 반드시 아래 3개 파일로 수렴해야 한다.

- `app_config.dart`: app의 look and feel, 초기 진입 location, 최소 shell config를 정의한다.
- `app_plugins.dart`: Plugin 조립과 runtime integration을 정의한다.
- `app_features.dart`: app에 노출할 Feature 등록 목록을 정의한다.

이 외의 파일이 두 번째 composition root가 되면 안 된다.

## Import 규칙

허용:

- `lib/features/**` -> `package:app_forge/engine/engine.dart`
- `lib/app/**` -> `package:app_forge/engine/engine.dart`
- `lib/app/**` -> `lib/features/**`
- 같은 slice 내부의 presentation -> domain/data

금지:

- `lib/engine/**` -> `lib/features/**`
- `lib/engine/**` -> `lib/app/**`
- Router 코드가 auth Feature를 직접 참조하는 것
- UI widget이나 page가 Firebase SDK를 직접 호출하는 것
- layer 경계를 가로지르는 임의의 전역 singleton wiring
- `lib/app/**` 또는 `lib/features/**`가 `lib/engine/src/**`를 직접 import하는 것

## Composition 모델

- Engine은 계약과 재사용 가능한 흐름을 정의한다.
- app은 concrete composition과 policy injection을 제공한다.
- Feature는 사용자 기능과 route/page 등록 정보를 제공한다.

이 구조는 Engine의 재사용성을 유지하고, 제품 도메인 policy가 Engine 안으로 새는 것을 막는다.
