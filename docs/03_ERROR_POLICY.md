# Error Policy

## 규칙

Feature 외부로 노출되는 비동기 API는 `Result<T>`를 반환해야 한다.

외부 예외는 data layer나 Repository layer를 벗어나기 전에 반드시 `AppError`로 매핑해야 한다.

## 최소 카테고리

- auth
- permission
- notFound
- network
- parsing
- unknown

## UI 처리 원칙

UI는 `AppError`만 처리한다.

구체적인 에러 표현 방식은 이후 Feature shell과 Router 작업이 들어오는 Phase에서 확장한다.
