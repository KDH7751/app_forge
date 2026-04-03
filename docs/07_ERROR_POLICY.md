# Error Policy

## 목적

이 문서는 feature failure와 앱 전역/runtime 에러를
어떤 계약으로 외부에 노출하고 처리할지에 대한 기준을 정의한다.

전체 구조와 흐름은 `docs/01_ARCHITECTURE.md`에서 정의하며,
이 문서는 그 중 에러 처리 규칙을 구체화한다.

이 둘은 연결될 수는 있지만 같은 모델이 아니다.

## 1. Feature failure

Feature 내부 비동기 실패와 validation 실패는
`Result<T>`와 `AppError`를 사용해 처리한다.

### 기본 규칙

- Feature 외부로 노출되는 비동기 API는 `Result<T>`를 반환해야 한다.
- 외부 예외는 data layer나 repository layer를 벗어나기 전에 `AppError`로 매핑해야 한다.
- feature UI는 raw exception이 아니라 `AppError`를 처리해야 한다.

### 원칙

- raw `FirebaseException` 등 외부 예외를 그대로 노출하지 않는다.
- 파싱/전송/권한 오류는 UI까지 throw로 전달하지 않는다.
- 에러 표현 방식은 Feature마다 제각각 만들지 않는다.
- UI는 실패 원인보다 `AppError` 계약을 기준으로 동작한다.

## 2. Global/runtime error

앱 전역/runtime 에러는 `ErrorHub` 기반 중앙 처리 흐름을 사용한다.

## Error Model

전역 에러 흐름은 다음 model을 사용한다.

- `ErrorEnvelope`
  - `error`
  - `stackTrace`
  - `domainError` (optional)
  - `source`
  - `timestamp`
- `ErrorDecision`
  - `shouldLog`
  - `shouldNotify`
  - `severity`
- `ErrorSource`
  - `ui`
  - `async`
  - `framework`
  - `platform`
  - `unknown`

## Policy 규칙

- ErrorPolicy는 `ErrorEnvelope`를 기반으로만 판단한다.
- domainError는 단순 metadata로만 전달된다.
- ErrorPolicy는 domainError의 존재 여부만 사용할 수 있다.
- domainError의 타입, 필드, 의미를 해석하면 안 된다.

## DefaultErrorPolicy

기본 규칙:

- `domainError` 존재 -> log + notify
- unknown error -> log only
- framework/platform -> error 또는 fatal

주의:

- DefaultErrorPolicy는 기본값이다.
- 실제 UX 요구사항에 따라 app에서 override해야 한다.

## UI 규칙

- 전역 에러 UI는 `ErrorDecision.shouldNotify`만 기준으로 반응한다.
- 전역 에러 listener는 app root에서 단 한 번만 등록한다.
- feature 내부에서 전역 error stream을 직접 listen하지 않는다.

## 3. Feature failure와 global/runtime error의 관계

- `AppError`는 feature-level 실패 표현이다.
- `ErrorEnvelope` / `ErrorDecision`은 app 전역/runtime 에러 처리 모델이다.
- `domainError`는 optional metadata이며, 필요 시 feature error를 담을 수 있다.
- 전역 정책은 `domainError`의 타입을 해석하지 않는다.
- `AppError`를 global error model로 승격하지 않는다.

## Phase 3.1 auth feature의 최소 AppErrorType

현재 Phase 3.1에서는 auth slice 안에서 아래 타입을 최소 범위로 구현한다.

- `userNotFound`
- `wrongPassword`
- `emailAlreadyInUse`
- `weakPassword`
- `invalidEmail`
- `invalidPassword`
- `passwordMismatch`
- `network`
- `unknown`

## 현재 상태

현재 Phase 3.1에서는 이 규칙이 auth slice에 최소 범위로 적용되어 있다.

즉,

- `Result<T>` / `AppError` 방향은 실제 auth login/signup/logout/reset 흐름에 적용되어 있고
- Firebase Auth / Firestore 예외는 repository에서 `AppError`로 변환된다.
- submit validation도 `Result<void>` / `AppError` 계약을 사용한다.

다만 shared core 승격은 아직 하지 않는다.

Phase 3.2부터는 여기에 더해
앱 전역/runtime 에러를 위한 `ErrorHub` 기반 처리 흐름이 별도로 도입되었다.

## Phase 3.1 UI 메시지 규칙

- auth는 UI 메시지를 반환하지 않는다.
- UI는 `AppErrorType`을 자체 메시지로 매핑한다.
- field validation 에러와 server 에러는 분리해서 표시한다.