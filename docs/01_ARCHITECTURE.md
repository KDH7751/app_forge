# Architecture

## 목적

이 Template은 재사용 가능한 Engine 인프라와
app 조립 코드, Feature 구현 코드를 분리하기 위해 설계되었다.

구조의 핵심 경계는 다음과 같다.

- `lib/engine/`는 재사용 가능한 Engine layer를 가진다.
- `lib/app/`은 이 앱의 composition root를 가진다.
- `lib/features/`는 제품 기능을 vertical slice 단위로 가진다.

## 최종 트리

```text
lib/
  main.dart
  bootstrap/
    bootstrap.dart
  engine/
    engine.dart
    src/
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
      presentation/
    login/
      presentation/
    home/
      presentation/
    profile/
      presentation/
    posts/
      presentation/
    settings/
      presentation/
  ui_kit/
```

## 폴더 책임

- `lib/engine/`: 재사용 가능한 Engine surface와 내부 구현을 가진다.
- `lib/bootstrap/`: runtime bootstrap host를 가진다. app 3파일을 소비하지만 source of truth는 아니다.
- `lib/engine/src/plugins`: engine이 소비하는 plugin 실행 계약을 가진다.
- `lib/engine/src/routing`: Route DSL, matcher, navigation state, RouterEngine 구현을 가진다.
- `lib/engine/src/shell`: EngineShell, FeatureShell 같은 shell UI 계약을 가진다.
- `lib/ui_kit/`: 여러 app에서 재사용 가능한 UI token과 widget을 가진다.
- `lib/app/`: 이 앱의 composition root이자 유일한 app 설정 지점을 가진다.
- `lib/features/`: vertical slice로 구성된 Feature module을 가진다.
- `lib/features/**/presentation`: Feature별 UI 또는 provider/controller 같은 presentation state를 가진다.
- `lib/features/**/domain`: 필요한 경우 Feature 계약, entity, error/result를 가진다.
- `lib/features/**/data`: 필요한 경우 repository 구현, datasource, 외부 SDK 연동을 가진다.

## app 설정 파일

app 전용 설정은 반드시 아래 3개 파일로 수렴해야 한다.

- `app_config.dart`: app의 look and feel, 초기 진입 location, 최소 shell config를 정의한다.
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
- 같은 slice 내부의 presentation -> domain/data

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

## auth / login 분리

- auth feature는 순수 기능 feature다.
- auth는 UI page를 소유하지 않는다.
- auth의 `presentation`은 widget page가 아니라 provider/controller layer를 의미한다.
- login feature는 auth 기능을 소비만 한다.
- login feature는 auth provider/controller를 사용하되 auth 계약이나 구현을 재정의하거나 복제하지 않는다.

## public Engine surface

- app과 Feature가 사용하는 유일한 public Engine import 경로는 `package:app_forge/engine/engine.dart`이다.
- `lib/engine/src/**`는 internal 구현이며 외부 계약이 아니다.
