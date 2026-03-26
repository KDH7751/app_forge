# Kickoff

## 정체성

이 저장소는 단일 토이 앱을 만들기 위한 저장소가 아니다.

목표는 여러 Flutter 앱에서 재사용 가능한 Flutter App Engine Template을 만드는 것이다.

이 Template은 복사해 사용할 수 있어야 하며,
이후 개발은 Engine을 계속 수정하는 방식이 아니라
Feature를 추가하는 방식으로 확장할 수 있어야 한다.

## 목표

- `lib/engine/`는 재사용 가능해야 한다.
- app 설정은 `lib/app/` 아래 3개 파일에서만 수행해야 한다.
- 이후 개발은 `lib/features/` 아래 Feature slice를 추가하는 방식으로 진행해야 한다.

## 핵심 원칙

- 단순함을 우선한다.
- Engine, app, Feature의 경계를 섞지 않는다.
- 설정 포인트를 최소화한다.
- Feature는 독립적으로 확장 가능한 단위여야 한다.

## 금지 기준

- Engine이 app을 알게 되는 것
- Engine이 Feature를 import하는 것
- app 설정 지점이 3개 파일 밖으로 퍼지는 것
- UI가 외부 SDK를 직접 호출하는 것
- Feature를 추가하는 대신 Engine을 계속 수정해야 하는 것