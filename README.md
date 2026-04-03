# Flutter App Engine Template

## 목적

이 저장소의 목적은 단일 토이 앱을 완성하는 것이 아니다.

목표는 여러 Flutter 앱에서 재사용할 수 있는 Flutter App Engine Template을 만드는 것이다.

이 Template은 새로운 프로젝트에서 복사해 사용할 수 있어야 하며,
이후 개발은 Engine을 계속 수정하는 방식이 아니라
Feature를 추가하는 방식으로 확장할 수 있어야 한다.

## 현재 상태

현재 Phase 3.2까지 완료되었다.

구현된 범위:

- `RouteDef` 기반 Route DSL
- `RouterEngine`
- route matching
- `NavigationState`
- `EngineShell`
- `FeatureShell`
- `Firebase.initializeApp()` bootstrap 진입
- 이메일/비밀번호 login / signup / logout / reset
- `AuthSession` provider
- app layer auth redirect
- `users/{uid}` upsert 보장
- auth 내부 최소 `AppError` / `Result<T>` / logger
- `auth_entry` form UI / controller 구조
- ErrorHub 기반 전역 에러 처리 구조
- ErrorPolicy / ErrorDecision 기반 에러 흐름
- Logger abstraction 및 MultiLogger
- root 단일 listener 기반 UI 에러 처리
- runZonedGuarded 기반 runtime bootstrap 구조
- 검증 라우트
  - `/login`
  - `/signup`
  - `/reset-password`
  - `/home`
  - `/profile`
  - `/posts/:id`

검증 상태:

- `flutter analyze` 통과
- `flutter test` 통과
- 실제 빌드 및 화면 이동 확인 완료

## 핵심 구조

```text
lib/
  main.dart
  bootstrap/   # runtime bootstrap host
  engine/      # 재사용 가능한 Engine layer
  ui_kit/      # 재사용 가능한 UI primitive와 token
  app/         # 이 앱의 composition root
  features/    # 제품 Feature
```

## app 설정 파일

app 설정은 아래 3개 파일에서만 수행한다.

- `lib/app/app_config.dart`
- `lib/app/app_plugins.dart`
- `lib/app/app_features.dart`

이 외의 파일이 두 번째 composition root가 되면 안 된다.

## 핵심 원칙

- Engine은 app이나 Feature를 알지 않는다.
- app 설정은 3개 파일로 수렴해야 한다.
- Feature만 추가해도 앱이 확장될 수 있어야 한다.
- Engine은 policy, flow, abstraction을 소유하고 concrete 구현은 app이 주입한다.
- app은 Engine, Plugin, Feature를 조립하는 composition root다.
- 각 Feature는 vertical slice로 확장되어야 한다.
- Feature는 필요한 layer만 가진다. 빈 `domain/`, `data/` 폴더를 강제하지 않는다.
- Feature 내부 기본 구조는 `ui/state/data/domain` 규칙을 따른다.
- auth의 state는 provider/controller를 뜻하며, login/signup/reset page는 별도 auth_entry feature의 ui가 소유한다.
- 전역 에러 처리는 ErrorHub -> Policy -> Logger/UI 흐름을 따른다.
- engine은 에러를 해석하지 않는다.
- UI는 ErrorDecision을 기반으로 표현만 수행한다.

## 현재 범위에 포함되지 않는 것

다음은 아직 현재 범위에 포함되지 않는다.

- shell 고급 커스터마이징
- route transition / analytics 확장
- role/status 기반 접근 제어
- 소셜 로그인
- shared error / logger core 승격

이 항목들은 이후 Phase에서 도입한다.

## 문서

핵심 문서:

- `docs/00_KICKOFF.md`: 프로젝트 정체성과 목표
- `docs/01_ARCHITECTURE.md`: 구조와 의존성 경계
- `docs/02_CODING_CONTRACT.md`: 구현 규칙
- `docs/03_ROUTING_GUIDE.md`: 라우팅 규칙
- `docs/04_DECISIONS.md`: 확정된 설계 결정

보조 문서:

- `docs/05_COMMENT_GUIDE.md`: 주석 규칙
- `docs/06_AI_WORKFLOW.md`: AI 협업 규칙
- `docs/07_ERROR_POLICY.md`: 에러 처리 방향
- `docs/08_ADOPTION_MAP.md`: 재사용/흡수 후보
