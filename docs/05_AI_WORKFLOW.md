# AI Workflow

## 기본 순서

1. 현재 코드와 문서를 먼저 확인한다.
2. public API를 확인하거나 먼저 정의한다.
3. 구현은 3개에서 5개 파일 단위 배치로 진행한다.
4. format, analyze, test로 검증한다.

## 필수 출력

- 변경 의도
- 변경 파일 목록
- 파일별 한 줄 책임
- 의존성 규칙 준수 여부
- 다음 체크리스트

## 금지 패턴

- UI에서 Firebase를 직접 호출하는 것
- throw 중심의 raw async 흐름을 유지하는 것
- Engine이 app이나 Feature를 import하는 것
