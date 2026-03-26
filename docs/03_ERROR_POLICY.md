# Error Policy

## 목적

이 문서는 비동기 실패를 어떤 형태로 외부에 노출할지에 대한 기준을 정의한다.

## 기본 규칙

- Feature 외부로 노출되는 비동기 API는 `Result<T>`를 반환해야 한다.
- 외부 예외는 data layer나 Repository layer를 벗어나기 전에 `AppError`로 매핑해야 한다.
- UI는 raw exception이 아니라 `AppError`만 처리해야 한다.

## 최소 카테고리

`AppError`는 최소한 다음 범주를 가져야 한다.

- auth
- permission
- notFound
- network
- parsing
- unknown

## 현재 상태

현재 Phase 2에서는 이 문서의 규칙을 **구조 기준으로만 유지**한다.

즉,
- `Result<T>` / `AppError` 방향은 확정되어 있지만
- 실제 구현과 Firebase/Auth 연동은 아직 포함하지 않는다.

이 부분은 이후 Phase에서 구체화한다.

## 원칙

- raw `FirebaseException`을 그대로 외부에 노출하지 않는다.
- 파싱/전송/권한 오류를 UI까지 throw로 전달하지 않는다.
- 에러 표현 방식은 Feature마다 제각각 만들지 않는다.
- UI는 실패 원인보다 `AppError` 계약을 기준으로 동작한다.