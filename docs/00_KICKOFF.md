# Kickoff

## 정체성

이 저장소는 단일 토이 앱을 만들기 위한 저장소가 아니다.

목표는 여러 Flutter 앱에서 재사용 가능한 Flutter App Engine Template을 만드는 것이다.

이 Template은 복사해 사용할 수 있어야 하며,
이후 개발은 Engine을 계속 수정하는 방식이 아니라
Feature를 추가하는 방식으로 확장할 수 있어야 한다.

## 목표

- `lib/engine/`는 재사용 가능해야 한다.
- `lib/modules/`는 다른 프로젝트에서도 거의 그대로 가져갈 수 있는 기본 module을 담아야 한다.
- `lib/features/`는 이 프로젝트에서 실제로 소비되는 consumer feature를 담아야 한다.
- app 설정은 `lib/app/` 아래 3개 파일에서만 수행해야 한다.

## 핵심 원칙

- 단순함을 우선한다.
- Engine, module, app, consumer feature의 경계를 섞지 않는다.
- 설정 포인트를 최소화한다.
- foundation, reusable module, consumer feature를 구분해서 읽는다.
- `modules/foundation`은 여러 module과 feature가 함께 기대는 얇은 공통 기반 타입 위치로 유지한다.
- auth는 일반 product feature가 아니라 reusable auth module에 가깝게 해석한다.
- auth_flow는 `auth_flow.dart` entry를 통해 auth를 실제 앱 UX로 소비하는 consumer feature로 읽는다.
- app은 modules와 features를 조립하는 composition root다.
- consumer feature는 module의 공개 표면을 소비해야 한다.
- feature failure 처리와 app 전역/runtime 에러 처리는 서로 다른 계약으로 유지한다.

구조와 구현 규칙은 `docs/01_ARCHITECTURE.md`와 `docs/02_CODING_CONTRACT.md`를 따른다.

## 금지 기준

- Engine이 app을 알게 되는 것
- Engine이 module이나 consumer feature를 import하는 것
- app 설정 지점이 3개 파일 밖으로 퍼지는 것
- consumer feature가 module의 concrete 구현 세부를 직접 아는 것
- UI가 외부 SDK를 직접 호출하는 것
- consumer feature를 추가하는 대신 reusable module이나 Engine을 계속 수정해야 하는 것
