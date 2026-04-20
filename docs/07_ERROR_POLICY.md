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

공통 계약 기준:

- `AppFailureType`은 provider-independent 의미 이름만 사용한다.
- `AppFailure` public contract는 `type`과 validation용 `fieldErrors`만 가진다.
- validation failure는 별도 예외 모델로 분리하지 않고 `AppFailureType.validation`으로 수렴한다.
- `fieldErrors`는 validation의 공식 필드 단위 표현이다.
- raw provider code, exception class, backend status, provider 원문 메시지는 data/repository boundary 밖으로 올리지 않는다.
- auth action failure contract와 `AuthSession` invalid public contract는 서로 다른 축이다.
- 예를 들어 auth action mapping의 `unauthorized`는 action 실행 실패 의미이고, Phase 3.5의 `InvalidReason.disabled` 같은 session invalid 의미를 대체하거나 흡수하지 않는다.
- 같은 raw provider 사실이라도 action 맥락이 다르면 다른 `AppFailureType`으로 정규화될 수 있다.
- feature-level failure 소비 기본 패턴은 feature별 failure presenter로 유지한다.
- presenter는 정규화된 `AppFailure`만 받아 사용자 문구와 로컬 처리/공용 피드백 후보 판단을 만든다.
- feature failure가 app root 공용 피드백 채널로 전달될 수 있어도 global/runtime error 모델로 승격하지 않는다.

`AppFailureType` 공식 범위:

- `validation`
- `invalidCredentials`
- `unauthorized`
- `permissionDenied`
- `notFound`
- `conflict`
- `rateLimited`
- `network`
- `unavailable`
- `unknown`

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
