# Error Policy

## 목적

이 문서는 비동기 실패를 어떤 형태로 외부에 노출할지에 대한 기준을 정의한다.

## 기본 규칙

- Feature 외부로 노출되는 비동기 API는 `Result<T>`를 반환해야 한다.
- 외부 예외는 data layer나 Repository layer를 벗어나기 전에 `AppError`로 매핑해야 한다.
- UI는 raw exception이 아니라 `AppError`만 처리해야 한다.

## 최소 타입

Phase 3.5 auth slice는 최소한 다음 타입을 가진다.

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

현재 Phase 3.5에서는 auth slice 안에서 이 규칙을 최소 범위로 구현한다.

즉,
- `Result<T>` / `AppError` 방향은 실제 auth login/signup/logout/reset 흐름에 적용되어 있고
- Firebase Auth / Firestore 예외는 repository에서 `AppError`로 변환된다.
- submit validation도 `Result<void>` / `AppError` 계약을 사용한다.

다만 shared core 승격은 아직 하지 않는다.

## Phase 3.5 UI 메시지 규칙

- auth는 UI 메시지를 반환하지 않는다.
- UI는 `AppErrorType`을 자체 메시지로 매핑한다.
- field validation 에러와 server 에러는 분리해서 표시한다.

## 원칙

- raw `FirebaseException`을 그대로 외부에 노출하지 않는다.
- 파싱/전송/권한 오류를 UI까지 throw로 전달하지 않는다.
- 에러 표현 방식은 Feature마다 제각각 만들지 않는다.
- UI는 실패 원인보다 `AppError` 계약을 기준으로 동작한다.
