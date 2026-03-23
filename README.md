# Flutter App Engine Template

## 목적

이 저장소의 목적은 단일 토이 앱을 완성하는 것이 아니다.

목표는 여러 Flutter 앱에서 재사용할 수 있는 App Engine Template을
구성하는 것이다. 이 Template은 새로운 프로젝트에서 복사해 사용할 수
있어야 하며, 이후에는 Feature를 추가하는 방식으로 확장할 수 있어야 한다.

기본 사용 방식은 다음과 같다.

1. 이 Template 구조를 기준으로 프로젝트를 시작한다.
2. app 진입 설정은 아래 3개 파일에서만 수행한다.
   - `lib/app/app_config.dart`
   - `lib/app/app_plugins.dart`
   - `lib/app/app_features.dart`
3. 제품 동작은 `lib/features/` 아래에서 Feature를 추가하거나 수정하는 방식으로 확장한다.

## 핵심 원칙

- Engine은 app이나 Feature를 알지 않는다.
- app 설정은 3개 파일로 수렴해야 한다.
- Feature만 추가해도 앱이 확장될 수 있어야 한다.
- Engine은 policy, flow, abstraction을 소유하고 concrete 구현은 app이 주입한다.
- app은 Engine, Plugin, Feature를 조립하는 composition root다.
- 각 Feature는 domain, data, presentation을 포함하는 완전한 vertical slice여야 한다.

## 목표 구조

```text
lib/
  engine/      # 재사용 가능한 Engine layer
  ui_kit/      # 재사용 가능한 UI primitive와 token
  main.dart
  app/         # 이 앱의 composition root
  features/    # 제품 Feature
```

## 고정 스택

- Flutter + Dart
- Riverpod
- go_router
- freezed + json_serializable
- Firebase Auth / Firestore / FCM / Crashlytics

## 비목표

- Engine 경계가 확정되기 전에 제품 Feature를 먼저 깊게 구현하는 것
- UI에서 Firebase를 직접 호출하는 것
- Router 내부에 auth policy를 하드코딩하는 것

## Phase 1 범위

Phase 1에서는 구조, 경계, public API, placeholder bootstrap만 고정한다.
실제 Router 구현, Firebase 연동, 로그인, 커뮤니티 기능은 이후 Phase에서 진행한다.

## 문서

- `docs/01_ARCHITECTURE.md`: 구조와 의존성 규칙
- `docs/02_CODING_CONTRACT.md`: 코딩 규칙과 layer 계약
- `docs/04_ROUTING_GUIDE.md`: Routing 방향과 Phase 1 placeholder 범위
- `docs/08_COMMENT_GUIDE.md`: 구조와 경계를 설명하는 주석 정책
