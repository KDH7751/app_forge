# Kickoff

## 정체성

이 저장소는 단일 토이 앱을 만들기 위한 저장소가 아니다.
목표는 재사용 가능한 Flutter App Engine Template을 만드는 것이다.

## 성공 조건

- `lib/engine/`는 여러 앱에서 재사용 가능해야 한다.
- app 설정은 `lib/app/` 아래 3개 파일에서만 이루어져야 한다.
- 기능 확장은 `lib/features/` 아래의 Feature slice를 추가하는 방식으로 진행되어야 한다.

## 작업 방식

- 구조를 먼저 확정하고 그다음에 Feature 작업으로 들어간다.
- 코드는 작은 배치로 나누어 수정한다.
- AI가 제안한 내용은 사람이 이해하고 리뷰할 수 있어야 한다.

## 강한 규칙

- 회사 코드나 독점 자산을 복사하지 않는다.
- Engine이 app이나 Feature를 알게 만들지 않는다.
- 편의를 이유로 Coding Contract를 우회하지 않는다.
