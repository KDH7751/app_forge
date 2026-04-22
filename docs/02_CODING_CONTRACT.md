# Coding Contract

## 목적

이 문서는 생성 코드와 수작업 코드가 같은 구현 규칙을 유지하도록 하기 위한 기준이다.

## 작업 단위

- 구현은 vertical slice 단위로 진행한다.
- public API를 먼저 정의하거나 확인한 뒤 구현을 채운다.
- 한 번에 구조와 기능을 동시에 크게 바꾸지 않는다.
- 하나의 구조 변경이나 기능 흐름을 닫기 위해 필요하면 여러 파일을 함께 수정할 수 있다.

## Layer 규칙

이 문서의 내부 layer 규칙은 `lib/modules/**`와 `lib/features/**`에 공통 적용한다.

```text
unit/
  ui/
  state/
  data/
  domain/   # 필요 시에만
```

레이어 책임:

- `ui`: widget, page, layout만 둔다. 상태 관리, 비즈니스 로직, 외부 호출을 넣지 않는다.
- `state`: UI 상태와 흐름을 제어한다. controller, provider, mapper, notice를 둔다.
- `data`: 외부 시스템 접근만 담당한다. Firebase, API, DB, datasource, repository 구현을 둔다.
- `domain`: 필요한 경우에만 둔다. entity, contract, 입력 모델, validation helper를 둔다.

추가 기준:

- Firebase나 외부 backend 호출은 `modules/**/data/**` 또는 `features/**/data/**` 아래에서만 허용한다.
- `state`는 기본적으로 flat 구조를 유지하고, controller/provider가 많을 때만 `controllers/`, `providers/` 하위 폴더를 만든다.
- `mapper`, `notice`는 별도 폴더로 분리하지 않는다.
- `presentation` 레이어는 새로 만들지 않는다.

## 비동기와 에러 규칙

- module 또는 feature 외부로 노출되는 모든 비동기 작업은 `Result<T>`를 반환해야 한다.
- raw `FirebaseException`, 파싱 에러, 전송 에러를 그대로 throw하지 않는다.
- 외부 실패는 `AppFailure`로 매핑한다.
- validation 본체는 domain/state에 둘 수 있지만 외부 SDK 호출은 data에서만 수행한다.

global/runtime error:

- 앱 전역/runtime 에러는 `ErrorHub` 흐름으로 처리한다.
- root UI는 `ErrorDecision` 기반으로 반응한다.
- feature 내부에서 전역 error stream을 직접 listen하지 않는다.

feedback:

- app-wide user feedback은 `FeedbackRequest`와 feedback dispatcher 흐름으로 처리한다.
- `FeedbackRequest`는 `AppFailure`를 대체하지 않는다.
- auth feature failure의 공식 root feedback 소비 패턴은 `AuthFailurePresenter -> AuthFeedbackCoordinator -> feedback dispatch`다.
- auth는 `AuthFeedbackFactory`를 별도 계층으로 유지하지 않고 coordinator에 흡수한다.
- feedback 중앙 계층은 request 표시 운영만 담당하고 failure 의미를 다시 해석하지 않는다.

세부 정책은 `docs/07_ERROR_POLICY.md`, 전체 구조는 `docs/01_ARCHITECTURE.md`를 따른다.

## Provider 규칙

- 기본 DI 방식은 Riverpod다.
- Provider 이름은 `Provider`로 끝나야 한다.
- Provider 소유권은 사용하는 slice 가까이에 둔다.
- 전역 service locator 사용은 피한다.
- controller/provider/mapper/notice는 module 또는 feature의 `state/` 아래에만 둔다.

## Import / Public Surface 규칙

- engine, module, `features/common`은 외부 소비 지점이 있을 때 public surface 파일을 둔다.
- 기본 기준은 `engine/engine.dart`, `modules/<name>/<name>.dart`, `modules/foundation/foundation.dart`, `features/common/common.dart`다.
- `modules/bootstrap/bootstrap.dart`는 bootstrap module의 유일한 public entry 배럴이다.
- `modules/feedback/feedback.dart`는 feedback module의 public surface다.
- consumer feature와 app은 module 내부 concrete 구현 대신 public surface를 먼저 소비한다.
- public surface에는 공개 계약, 설정 표면, 소비자에게 필요한 provider/controller/helper만 노출한다.
- assembly, provider-specific runtime/support, parser, datasource, 내부 wiring 세부는 public surface에 올리지 않는다.

engine 경계:

- engine public surface는 `lib/engine/engine.dart` 하나다.
- runtime code inside `lib/`는 relative import를 기본으로 사용한다.
- `lib/engine/src/**`는 internal 구현이며 외부 계약이 아니다.
- feature는 module public surface를 소비할 수 있지만 concrete/internal 구현 세부를 직접 import하면 안 된다.

## 의존성 방향

- module은 `lib/engine/engine.dart`에 의존할 수 있다.
- feature는 `lib/engine/engine.dart`와 module public surface에 의존할 수 있다.
- feature는 `features/common` 같은 consumer-side shared asset을 참조할 수 있다.
- app은 `lib/engine/engine.dart`, module public surface, feature에 의존할 수 있다.

- Engine은 app, module consumer, feature consumer를 import하면 안 된다.
- module은 feature나 `features/common`의 consumer 구현에 의존하면 안 된다.
- feature는 module concrete 구현 세부에 직접 의존하면 안 된다.
- app은 module concrete action, endpoint, parsing, provider-specific detail을 직접 소유하면 안 된다.

내부 의존성 방향:

- `ui -> state -> data/domain`
- `ui`는 `state`만 참조할 수 있다.
- `state`는 `data`와 `domain`을 참조할 수 있다.
- `data`는 `domain`을 참조할 수 있다.
- `ui`는 `data`나 `domain`을 직접 참조할 수 없다.
- `domain`은 `ui/state/data`를 참조할 수 없다.
- `data`는 `ui/state`를 참조할 수 없다.

## 네이밍 규칙

- 파일 이름은 `snake_case.dart`
- type 이름은 `PascalCase`
- Provider 이름은 설명적인 `camelCaseProvider`
- placeholder 성격이면 이름에서 그 상태가 드러나야 한다

## 금지 패턴

- UI에서 Firebase를 직접 호출하는 것
- `ui/` 내부에 controller/provider/mapper를 정의하는 것
- `state/` 외 위치에 controller/provider/mapper/notice를 두는 것
- `data/` 외 위치에서 Firebase나 외부 API를 호출하는 것
- validation/helper를 data layer의 concrete SDK 호출과 섞는 것
- consumer feature가 module concrete 구현을 직접 아는 것
- module이 consumer feature나 `features/common`에 의존하는 것
- `features/common`을 reusable module이나 misc/shared 창고처럼 확장하는 것
- `modules/foundation`에 module-local concrete 구현이나 project-specific policy를 두는 것
- Engine이 app, module, consumer feature를 import하는 것
- 임의의 singleton으로 layer 경계를 우회하는 것
- 설정 편의를 이유로 public surface를 계속 넓히는 것
- raw `AppFailure`를 `FeedbackRequest` 대신 중앙 feedback 계층에 직접 넘기는 것
