# Flutter App Engine Template

## 목적

이 저장소의 목적은 단일 토이 앱 완성이 아니다.
여러 Flutter 앱에서 재사용할 수 있는 **Flutter App Engine Template**을 만드는 것이 목표다.

## 현재 상태

현재 Phase 3.8까지 완료되었다.

구현된 범위:

- RouteDef 기반 routing, RouterEngine, NavigationState, EngineShell / FeatureShell
- app plugin 기반 Firebase runtime preparation
- app provider set composition (`auth / domain data / file/storage / analytics/crash`)
- reusable auth module과 project-level auth consumer feature 분리
- auth 기능 (`login / signup / logout / reset / changePassword / deleteAccount`)
- AuthSession public contract (`Authenticated / Unauthenticated / Invalid / Pending`)
- app layer auth redirect와 Session Integrity
- Result<T> / AppFailure 기반 feature failure 처리
- feature failure baseline (`AppFailureType`, validation `fieldErrors`, auth normalization)
- app-wide user feedback system (`snackbar / dialog / banner / modalSheet`)
- auth action failure -> `AuthFeedbackCoordinator` -> feedback request 연결
- session invalid -> root sessionExpired banner 연결
- ErrorHub / ErrorPolicy / ErrorDecision 기반 전역 에러 처리
- runZonedGuarded 기반 runtime bootstrap

검증 상태:

- `flutter analyze` 통과
- `flutter test` 통과
- 실제 빌드 및 화면 이동 확인 완료

## 구조 해석 기준

```text
lib/
  app/         # 이 프로젝트의 composition root
  engine/      # domain-agnostic infrastructure
  modules/     # 재사용 가능한 module + foundation
  features/    # project-level consumer feature
    common/    # common.dart만 가진 project-level shared surface
  ui_kit/      # 재사용 가능한 UI primitive와 token
```

핵심 읽기 기준:

- `app`은 이 프로젝트의 composition root다.
- app 설정 source of truth는 `app_config.dart`, `app_plugins.dart`, `app_features.dart` 3파일로 유지한다.
- engine public surface는 `lib/engine/engine.dart` 하나다.
- runtime code inside `lib/`는 relative import를 기본으로 사용하며 `lib/engine/src/**`를 직접 import하지 않는다.
- feature는 engine public surface와 module public surface를 소비할 수 있지만 module concrete/internal 구현은 직접 소비하지 않는다.
- `lib/modules/bootstrap/bootstrap.dart`는 bootstrap module의 유일한 public entry 배럴이다.
- bootstrap은 host/runtime wiring만 담당하며 app 설정 source of truth를 늘리거나 대체하지 않는다.
- `lib/modules/feedback`는 3.8 잠금 범위를 구현하기 위한 reusable module이며, 범위 밖 범용 확장을 선행하지 않는다.
- auth의 공식 root feedback 소비 패턴은 `AuthFailurePresenter -> AuthFeedbackCoordinator -> feedback dispatch`다.
- `snackbar`와 `banner`는 root overlay presenter 경로로 표시되고, `dialog`와 `modalSheet`는 feedback host의 navigator/context 경로를 유지한다.
- `FeedbackRequest`는 `AppFailure`를 대체하지 않으며, ErrorHub와 feedback은 모델/정책/입력 경로를 분리 유지한다.

## 문서 읽기 순서

- `docs/00_KICKOFF.md`, `docs/01_ARCHITECTURE.md`: 전체 구조와 책임 경계
- `docs/02_CODING_CONTRACT.md`: 구현 규칙과 import/public surface 기준
- `docs/03_ROUTING_GUIDE.md`: route DSL과 navigation 흐름
- `docs/07_ERROR_POLICY.md`: feature failure와 global error 구분
- `docs/04_DECISIONS.md`: 실제로 잠긴 결정
- `docs/05_COMMENT_GUIDE.md`: 주석 작성 기준
- `docs/06_AI_WORKFLOW.md`: AI 작업 순서와 출력 기준
- `docs/08_ADOPTION_MAP.md`: 재사용/확장 후보

## 현재 범위에 포함되지 않는 것

- shell 고급 커스터마이징
- route transition / analytics 확장
- push / notification provider set
- role/status 기반 접근 제어
- 소셜 로그인
- shared error / logger core 승격
