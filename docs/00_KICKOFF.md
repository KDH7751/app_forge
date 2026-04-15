# Kickoff

## 목적

이 문서는 이 저장소를 처음 읽을 때의 시작 안내와 문서 읽기 순서를 정리한다.
구조 규칙과 구현 규칙의 source of truth는 각 전용 문서를 따른다.

## 이 저장소를 읽는 기준

- 이 저장소는 단일 토이 앱 완성이 아니라 Flutter App Engine Template을 만드는 저장소다.
- 새로운 기능은 Engine을 계속 수정하는 방식보다 feature를 추가하는 방향을 우선한다.
- 현재 구조 해석과 잠금 기준은 `docs/01_ARCHITECTURE.md`, `docs/02_CODING_CONTRACT.md`, `docs/04_DECISIONS.md`를 기준으로 읽는다.

## 권장 읽기 순서

1. `README.md`
현재 상태, 범위, 전체 진입점을 먼저 확인한다.

2. `docs/01_ARCHITECTURE.md`
구조, 책임 경계, 의존 방향, composition 기준을 읽는다.

3. `docs/02_CODING_CONTRACT.md`
구현 규칙, import/public surface 규칙, layer별 금지/허용을 확인한다.

4. `docs/03_ROUTING_GUIDE.md`
routing DSL, RouterEngine, NavigationState, shell 규칙을 읽는다.

5. `docs/07_ERROR_POLICY.md`
feature failure와 global/runtime error의 경계를 읽는다.

6. `docs/04_DECISIONS.md`
실제로 잠긴 결정만 확인한다.

## 나머지 참고 문서

- `docs/05_COMMENT_GUIDE.md`: 주석 작성 기준
- `docs/06_AI_WORKFLOW.md`: AI 작업 순서와 출력 기준
- `docs/08_ADOPTION_MAP.md`: 재사용/확장 후보와 범위 판단 기준
