# Coding Contract

## 목적

이 문서는 생성 코드와 수작업 코드가 Phase가 바뀌어도 일관된 규칙을 유지하도록 하기 위한 기준이다.

## 작업 단위

- 구현은 vertical slice 단위로 진행한다.
- 구현은 가능한 한 검토 가능한 단위로 진행한다.
- 하나의 구조 변경이나 기능 흐름을 자연스럽게 닫기 위해 필요하다면 여러 파일을 한 번에 수정할 수 있다.
- public API를 먼저 정의하거나 확인한 뒤 구현을 채운다.
- 한 번에 구조와 기능을 동시에 크게 바꾸지 않는다.

## Feature 구조 규칙 (UI / State / Data)

Feature는 다음 구조를 기본으로 사용한다.

```text
feature/
  ui/
  state/
  data/
  domain/   # 필요 시에만
```

각 레이어의 책임:

- `ui`:
  - widget, page, layout만 가진다
  - 상태 관리, 비즈니스 로직, 외부 호출을 포함하지 않는다
- `state`:
  - UI 상태와 흐름을 제어한다
  - controller, provider, mapper, UI event(notice)를 포함한다
- `data`:
  - 외부 시스템 접근만 담당한다
  - Firebase, API, DB, datasource, repository 구현을 포함한다
- `domain`:
  - 필요한 경우에만 둔다
  - `AppError`, `Result`, entity, repository contract 같은 feature 계약을 포함할 수 있다

Firebase나 외부 backend 호출은 `features/**/data/**` 아래에서만 허용한다.
UI는 외부 SDK를 직접 호출하면 안 된다.

### state 내부 구조 규칙

`state` 내부는 기본적으로 flat 구조를 유지한다.

다음 조건에서만 하위 폴더를 허용한다.

- controller 또는 provider 파일이 5개 이상인 경우

허용되는 하위 폴더:

- `controllers/`
- `providers/`

`mapper`, `notice`는 별도 폴더로 분리하지 않는다.

### domain / data 생성 기준

`domain`은 다음 조건에서만 생성한다.

- feature 내부에서 재사용되는 entity 또는 contract가 2개 이상 존재할 때
- `Result`, `AppError` 외에 추가적인 도메인 개념이 필요한 경우

`data`는 다음 조건에서만 생성한다.

- 외부 시스템 호출(Firebase, API 등)이 존재할 때
- repository 또는 datasource가 필요한 경우

### notice 정의

`notice`는 화면 간 또는 화면 내부에서 사용하는 일회성 UI 이벤트 전달 객체다.

예:

- navigation 결과 전달
- 성공/완료 이벤트 전달

`notice`는 상태로 저장되지 않으며, 영속성을 가지지 않는다.

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
- controller/provider/mapper/notice는 `state/` 아래에만 둔다.

## 의존성 방향

- Feature는 `lib/engine/engine.dart`에 의존할 수 있다.
- app은 `lib/engine/engine.dart`와 Feature에 의존할 수 있다.
- Engine은 app이나 Feature에 의존하면 안 된다.
- Feature 내부 의존성 방향은 `ui -> state -> data/domain`으로 고정한다.
- `ui`는 `state`만 참조할 수 있다.
- `state`는 `data`와 `domain`을 참조할 수 있다.
- `data`는 `domain`을 참조할 수 있다.
- `ui`는 `data`나 `domain`을 직접 참조할 수 없다.
- `domain`은 `ui/state/data`를 참조할 수 없다.
- `data`는 `ui/state`를 참조할 수 없다.

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
- `presentation/` 레이어를 새로 만드는 것
- `ui/` 내부에 controller/provider/mapper를 정의하는 것
- `state/` 외 위치에 controller/provider/mapper/notice를 두는 것
- `data/` 외 위치에서 Firebase나 외부 API를 호출하는 것
- raw throw 기반 async 흐름을 그대로 외부에 노출하는 것
- Engine이 app이나 Feature를 import하는 것
- 임의의 singleton으로 layer 경계를 우회하는 것
- 설정 편의를 이유로 public surface를 계속 넓히는 것
