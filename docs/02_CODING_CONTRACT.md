# Coding Contract

## 목적

이 문서는 생성 코드와 수작업 코드가 Phase가 바뀌어도 일관된 규칙을 유지하도록 하기 위한 기준이다.

주석 규칙은 `docs/08_COMMENT_GUIDE.md`에 정의되어 있으며, 이 문서와 함께 Coding Contract의 일부로 취급한다.

## 작업 단위

- 구현은 vertical slice 단위로 진행한다.
- 파일 변경은 가능하면 3개에서 5개 단위 배치로 나눈다.
- public API를 먼저 정의하거나 확인한 뒤 구현을 채운다.

## Layer 규칙

- `presentation/`: widget, view state 매핑, 사용자 상호작용을 담당한다.
- `domain/`: Feature가 소유하는 entity와 비즈니스 규칙을 담당한다.
- `data/`: Repository와 datasource 구현을 담당한다.
- Firebase 호출은 `features/**/data/**` 아래에서만 허용한다.

UI는 Firebase를 직접 호출하면 안 된다.

## 의존성 방향

- Feature는 `lib/engine/engine.dart`에 의존할 수 있다.
- app은 `lib/engine/engine.dart`와 Feature에 의존할 수 있다.
- Engine은 app이나 Feature에 의존하면 안 된다.

이 저장소 안에서 app과 Feature는 `package:app_forge/engine/engine.dart`를 import한다.
이 package 경로가 runtime code에서 허용되는 유일한 public Engine surface다.

## 비동기와 에러 규칙

- Feature 외부로 노출되는 모든 비동기 작업은 `Result<T>`를 반환한다.
- raw `FirebaseException`, 파싱 에러, 전송 에러를 그대로 throw하지 않는다.
- 외부 실패는 `AppError`로 매핑한다.
- UI는 `AppError`만 처리한다.

## Provider 규칙

- 기본 DI 방식은 Riverpod다.
- Provider 이름은 `Provider`로 끝나야 한다.
- Provider 소유권은 사용하는 slice 가까이에 둔다.
- 전역 service locator 사용은 피한다.

## 네이밍 규칙

- 파일 이름은 `snake_case.dart`를 사용한다.
- type 이름은 `PascalCase`를 사용한다.
- Provider 이름은 설명적인 `camelCaseProvider`를 사용한다.
- 최종 구현이 아닌 경우 placeholder임을 이름에서 분명히 드러낸다.

## Engine 노출 규칙

- app과 Feature는 `package:app_forge/engine/engine.dart`만 Engine import 경로로 사용해야 한다.
- `lib/engine/src/**`는 internal 구현이며 외부 계약이 아니다.
