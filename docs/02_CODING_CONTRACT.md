# Coding Contract

## 목적

이 문서는 생성 코드와 수작업 코드가 Phase가 바뀌어도 일관된 규칙을 유지하도록 하기 위한 기준이다.

## 작업 단위

- 구현은 vertical slice 단위로 진행한다.
- 구현은 가능한 한 검토 가능한 단위로 진행한다.
- 하나의 구조 변경이나 기능 흐름을 자연스럽게 닫기 위해 필요하다면 여러 파일을 한 번에 수정할 수 있다.
- public API를 먼저 정의하거나 확인한 뒤 구현을 채운다.
- 한 번에 구조와 기능을 동시에 크게 바꾸지 않는다.

## Layer 규칙

- `presentation/`: widget, 화면 구성, 사용자 상호작용, view state 매핑을 담당한다.
- `domain/`: entity, 도메인 계약, 비즈니스 규칙을 담당한다.
- `data/`: repository 구현, datasource 구현, 외부 시스템 연동, dto / mapper를 담당한다.

Firebase나 외부 backend 호출은 `features/**/data/**` 아래에서만 허용한다.
UI는 외부 SDK를 직접 호출하면 안 된다.

## 비동기와 에러 규칙

- Feature 외부로 노출되는 모든 비동기 작업은 `Result<T>`를 반환해야 한다.
- raw `FirebaseException`, 파싱 에러, 전송 에러를 그대로 throw하지 않는다.
- 외부 실패는 `AppError`로 매핑한다.
- UI는 `AppError`만 처리한다.

구체적인 에러 카테고리와 매핑은 `docs/07_ERROR_POLICY.md`에서 다룬다.

## Provider 규칙

- 기본 DI 방식은 Riverpod다.
- Provider 이름은 `Provider`로 끝나야 한다.
- Provider 소유권은 사용하는 slice 가까이에 둔다.
- 전역 service locator 사용은 피한다.

## 의존성 방향

- Feature는 `lib/engine/engine.dart`에 의존할 수 있다.
- app은 `lib/engine/engine.dart`와 Feature에 의존할 수 있다.
- Engine은 app이나 Feature에 의존하면 안 된다.

이 저장소 안에서 app과 Feature는
`package:app_forge/engine/engine.dart`를 import한다.

이 package 경로가 runtime code에서 허용되는 유일한 public Engine surface다.

## 네이밍 규칙

- 파일 이름은 `snake_case.dart`를 사용한다.
- type 이름은 `PascalCase`를 사용한다.
- Provider 이름은 설명적인 `camelCaseProvider`를 사용한다.
- placeholder 성격이면 이름에서 그 상태가 드러나야 한다.

## Engine 노출 규칙

- app과 Feature는 `package:app_forge/engine/engine.dart`만 Engine import 경로로 사용해야 한다.
- `lib/engine/src/**`는 internal 구현이며 외부 계약이 아니다.
- public API는 필요한 contract만 노출해야 한다.

## 금지 패턴

- UI에서 Firebase를 직접 호출하는 것
- raw throw 기반 async 흐름을 그대로 외부에 노출하는 것
- Engine이 app이나 Feature를 import하는 것
- 임의의 singleton으로 layer 경계를 우회하는 것
- 설정 편의를 이유로 public surface를 계속 넓히는 것