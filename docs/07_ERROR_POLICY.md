# Error Policy

## 목적

이 문서는 feature failure와 앱 전역/runtime error를 어떤 계약으로 처리하는지 정리한다.
전체 구조는 `docs/01_ARCHITECTURE.md`, 일반 구현 규칙은 `docs/02_CODING_CONTRACT.md`를 따른다.

## 1. Feature failure

feature 내부 비동기 실패와 validation 실패는 `Result<T>`와 `AppFailure`를 사용해 처리한다.

기본 규칙:

- feature 외부로 노출되는 비동기 API는 `Result<T>`를 반환한다.
- 외부 예외는 data layer나 repository layer를 벗어나기 전에 `AppFailure`로 매핑한다.
- feature UI는 raw exception이 아니라 `AppFailure`를 처리한다.

원칙:

- raw `FirebaseException` 같은 외부 예외를 그대로 노출하지 않는다.
- 파싱/전송/권한 오류를 UI까지 throw로 전달하지 않는다.
- UI는 실패 원인 문자열보다 `AppFailure` 계약을 기준으로 동작한다.

## 2. Global/runtime error

앱 전역/runtime error는 `ErrorHub` 기반 중앙 처리 흐름을 사용한다.

핵심 model:

- `ErrorEnvelope`
- `ErrorDecision`
- `ErrorSource`

흐름:

```text
[Error 발생]
  ↓
ErrorHub
  ↓
ErrorPolicy
  ↓
ErrorDecision
  ↓
 ├─ Logger
 └─ root UI listener
```

정책 규칙:

- ErrorPolicy는 `ErrorEnvelope`를 기준으로 판단한다.
- `domainError`는 optional metadata로만 전달된다.
- ErrorPolicy는 `domainError`의 타입, 필드, 의미를 해석하지 않는다.

UI 규칙:

- 전역 에러 UI는 `ErrorDecision.shouldNotify`만 기준으로 반응한다.
- 전역 에러 listener는 app root에서 단 한 번만 등록한다.
- feature 내부에서 전역 error stream을 직접 listen하지 않는다.
- 실제 사용자 메시지 변환은 feature mapper 경로를 사용한다.
- feature UI의 local helper는 전역 `ErrorPolicy`를 대체하지 않는다.

## 3. 두 축의 경계

- `AppFailure`는 feature-level failure 표현이다.
- `ErrorEnvelope` / `ErrorDecision`은 app 전역/runtime error 처리 모델이다.
- `domainError`는 optional metadata일 뿐, 두 축을 하나의 모델로 합치지 않는다.
- `AppFailure`를 global error model로 승격하지 않는다.
