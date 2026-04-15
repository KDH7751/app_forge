# Coding Contract

## 목적

이 문서는 생성 코드와 수작업 코드가 Phase가 바뀌어도 일관된 규칙을 유지하도록 하기 위한 기준이다.

## 작업 단위

- 구현은 vertical slice 단위로 진행한다.
- 구현은 가능한 한 검토 가능한 단위로 진행한다.
- 하나의 구조 변경이나 기능 흐름을 자연스럽게 닫기 위해 필요하다면 여러 파일을 한 번에 수정할 수 있다.
- public API를 먼저 정의하거나 확인한 뒤 구현을 채운다.
- 한 번에 구조와 기능을 동시에 크게 바꾸지 않는다.

## Module / Feature 구조 규칙 (UI / State / Data)

이 문서의 내부 layer 규칙은 `lib/modules/**`와 `lib/features/**`에 공통 적용한다.
최상위 분류는 재사용성/consumer 역할로 판단하고, 내부 구조는 아래 layer 규칙으로 판단한다.

reusable module과 consumer feature는 다음 구조를 기본으로 사용한다.

```text
unit/
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
  - entity, repository contract, module-local 입력 모델과 validation helper 같은 계약을 포함할 수 있다
  - module 또는 feature action의 validation helper와 input model도 둘 수 있다

Firebase나 외부 backend 호출은 `modules/**/data/**` 또는 `features/**/data/**` 아래에서만 허용한다.
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

- module 또는 feature 내부에서 재사용되는 entity 또는 contract가 2개 이상 존재할 때
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

### Module / Feature async failure

- module 또는 feature 외부로 노출되는 모든 비동기 작업은 `Result<T>`를 반환해야 한다.
- raw `FirebaseException`, 파싱 에러, 전송 에러를 그대로 throw하지 않는다.
- 외부 실패는 `AppError`로 매핑한다.
- UI는 module 또는 feature async 결과에서 `AppError`를 처리한다.
- validation 본체는 domain/state에 둘 수 있지만, 외부 SDK 호출은 data에서만 수행한다.

### Global/runtime error

- 앱 전역/runtime 에러는 `ErrorHub` 흐름으로 처리한다.
- root UI는 전역 에러 흐름에서 `ErrorDecision` 기반으로 반응한다.
- feature 내부에서 전역 error stream을 직접 listen하지 않는다.

구체적인 전역 에러 구조와 정책은 `docs/07_ERROR_POLICY.md`를 따른다.
에러 처리의 전체 구조와 흐름은 `docs/01_ARCHITECTURE.md`를 참고한다.

## Provider 규칙

- 기본 DI 방식은 Riverpod다.
- Provider 이름은 `Provider`로 끝나야 한다.
- Provider 소유권은 사용하는 slice 가까이에 둔다.
- 전역 service locator 사용은 피한다.
- controller/provider/mapper/notice는 module 또는 feature의 `state/` 아래에만 둔다.

## Public Surface 규칙

- engine, module, `features/common`은 외부 소비 지점이 있을 때 public surface 파일을 둔다.
- 기본 기준은 `engine/engine.dart`, `modules/<name>/<name>.dart`, `modules/foundation/foundation.dart`, `features/common/common.dart`다.
- consumer feature와 app은 module 내부 concrete 구현 대신 public surface를 먼저 소비하도록 정리한다.
- public surface에는 공개 계약, 설정 표면, 소비자에게 필요한 provider/controller/helper만 노출한다.
- assembly, provider-specific runtime/support, parser, datasource, 내부 wiring 세부는 public surface에 올리지 않는다.
- session recovery tuning, lifecycle hold counter 같은 module 내부 concern도 public surface에 올리지 않는다.
- `modules/bootstrap/bootstrap.dart`는 예외적으로 barrel이 아니라 기능 파일 자체가 진입점이다.

## foundation 배치 기준

- `modules/foundation`에는 여러 module과 feature가 함께 기대는 얇은 공통 기반 타입/계약 후보를 둔다.
- `modules/foundation`은 engine infra를 대체하지 않는다.
- runtime/routing/shell/error hub 같은 infra는 foundation이 아니라 engine에 둔다.
- 특정 module 내부 구현 세부나 project-level policy, consumer UI helper는 foundation에 두지 않는다.
- auth 밖에서도 읽히는 `AppError`, `Result` 같은 타입은 foundation에 둔다.

## 의존성 방향

- module은 `lib/engine/engine.dart`에 의존할 수 있다.
- feature는 `lib/engine/engine.dart`와 module의 공개 표면에 의존할 수 있다.
- feature는 `features/common` 같은 consumer-side shared asset을 참조할 수 있다.
- app은 `lib/engine/engine.dart`, module의 공개 표면, feature에 의존할 수 있다.
- Engine은 app이나 Feature에 의존하면 안 된다.
- Engine은 module이나 `features/common`에도 의존하면 안 된다.
- module은 feature나 `features/common`의 consumer 구현에 의존하면 안 된다.
- feature는 module의 concrete 구현 세부에 직접 의존하면 안 된다.
- app은 module의 concrete action, endpoint, parsing, provider-specific implementation detail을 직접 소유하면 안 된다.
- module 또는 feature 내부 의존성 방향은 `ui -> state -> data/domain`으로 고정한다.
- `ui`는 `state`만 참조할 수 있다.
- `state`는 `data`와 `domain`을 참조할 수 있다.
- `data`는 `domain`을 참조할 수 있다.
- `ui`는 `data`나 `domain`을 직접 참조할 수 없다.
- `domain`은 `ui/state/data`를 참조할 수 없다.
- `data`는 `ui/state`를 참조할 수 없다.

이 저장소 안에서 app, module, feature는
`package:app_forge/engine/engine.dart`를 import한다.

이 package 경로가 runtime code에서 허용되는 유일한 public Engine surface다.

## 네이밍 규칙

- 파일 이름은 `snake_case.dart`를 사용한다.
- type 이름은 `PascalCase`를 사용한다.
- Provider 이름은 설명적인 `camelCaseProvider`를 사용한다.
- placeholder 성격이면 이름에서 그 상태가 드러나야 한다.

## Engine 노출 규칙

- app, module, feature는 `package:app_forge/engine/engine.dart`만 Engine import 경로로 사용해야 한다.
- `lib/engine/src/**`는 internal 구현이며 외부 계약이 아니다.
- public API는 필요한 contract만 노출해야 한다.

## 금지 패턴

- UI에서 Firebase를 직접 호출하는 것
- `presentation/` 레이어를 새로 만드는 것
- `ui/` 내부에 controller/provider/mapper를 정의하는 것
- `state/` 외 위치에 controller/provider/mapper/notice를 두는 것
- `data/` 외 위치에서 Firebase나 외부 API를 호출하는 것
- validation/helper를 data layer의 concrete SDK 호출과 섞는 것
- raw throw 기반 async 흐름을 그대로 외부에 노출하는 것
- consumer feature가 module의 concrete 구현을 직접 아는 것
- module이 consumer feature나 `features/common`에 의존하는 것
- `features/common`을 reusable module이나 misc/shared 창고처럼 확장하는 것
- `modules/foundation`에 module-local concrete 구현이나 project-specific policy를 두는 것
- Engine이 app, module, consumer feature를 import하는 것
- 임의의 singleton으로 layer 경계를 우회하는 것
- 설정 편의를 이유로 public surface를 계속 넓히는 것
