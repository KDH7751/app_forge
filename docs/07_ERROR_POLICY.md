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

현재 Phase 3에서는 auth slice 안에서 이 규칙을 최소 범위로 구현한다.

즉,
- `Result<T>` / `AppError` 방향은 실제 auth login/logout 흐름에 적용되어 있고
- Firebase Auth / Firestore 예외는 repository에서 `AppError`로 변환된다.

다만 shared core 승격은 아직 하지 않는다.

## Phase 3 auth 메시지 규칙

현재 auth UI에 노출 가능한 메시지는 아래 4개만 허용한다.

- 사용자를 찾을 수 없습니다
- 비밀번호가 올바르지 않습니다
- 네트워크 문제로 로그인할 수 없습니다
- 로그인에 실패했습니다. 다시 시도해주세요

## 원칙

- raw `FirebaseException`을 그대로 외부에 노출하지 않는다.
- 파싱/전송/권한 오류를 UI까지 throw로 전달하지 않는다.
- 에러 표현 방식은 Feature마다 제각각 만들지 않는다.
- UI는 실패 원인보다 `AppError` 계약을 기준으로 동작한다.
