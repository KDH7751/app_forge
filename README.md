# Flutter App Engine Template

## 목적

이 저장소의 목적은 단일 토이 앱을 완성하는 것이 아니다.

여러 Flutter 앱에서 재사용할 수 있는 **Flutter App Engine Template**을 만드는 것이 목표다.

이 Template은 새로운 프로젝트에서 복사해 사용할 수 있어야 하며,
이후 개발은 Engine을 수정하는 방식이 아니라
Feature를 추가하는 방식으로 확장되어야 한다.

---

## 현재 상태

현재 Phase 3.6까지 완료되었다.

구현된 범위:

- RouteDef 기반 Route DSL
- RouterEngine
- route matching
- NavigationState
- EngineShell / FeatureShell
- app plugin 기반 Firebase runtime preparation
- app provider set composition (`auth / domain data / file/storage / analytics/crash`)
- auth 기능 (login / signup / logout / reset / changePassword / deleteAccount)
- reusable auth module과 project-level auth consumer feature 분리
- AuthFacade + ...Action + auth provider set assembly
- AuthSession public contract (`Authenticated / Unauthenticated / Invalid / Pending`)
- app layer auth redirect
- users/{uid} upsert 정책
- Session Integrity (`users/{uid}` 부재 / blocked / disabled / auth provider server-side delete·disable 감지)
- invalid session 기반 보호 라우트 즉시 이탈 + 강제 logout 연결
- login/signup 직후 pending placeholder 처리
- profile 기반 임시 post-login account action UI
- Result<T> / AppError 기반 feature failure 처리
- ErrorHub 기반 전역 에러 처리 구조
- ErrorPolicy / ErrorDecision
- Logger abstraction + MultiLogger
- root 단일 listener 기반 UI 에러 처리
- runZonedGuarded 기반 runtime bootstrap

검증 상태:

- `flutter analyze` 통과
- `flutter test` 통과
- 실제 빌드 및 화면 이동 확인 완료

---

## 구조 해석 기준

```text
lib/
  app/         # 이 프로젝트의 composition root
  engine/      # domain-agnostic infrastructure
  modules/     # 재사용 가능한 기본 module + foundation
  features/    # project-level consumer feature
    common/    # common.dart만 가진 project-level shared surface 위치
  ui_kit/      # 재사용 가능한 UI primitive와 token
```

현재 구조 해석은 `modules/bootstrap`, `modules/auth`, `features/auth_flow` 기준을 따른다.

---

## 구조 핵심 요약

- engine → domain-agnostic infrastructure를 소유한다
- modules → 재사용 가능한 domain-aware module과 얇은 shared foundation을 소유한다
- features → 이 프로젝트의 consumer flow와 product slice를 소유한다
- app → modules와 features를 실제 앱으로 조립하는 composition root다

- feature failure → Result<T> / AppError
- global error → ErrorHub / ErrorPolicy / ErrorDecision

이 둘은 **서로 다른 계약이며 분리된 흐름이다.**

---

## app 설정 파일

app 설정은 반드시 아래 3개 파일로 수렴한다.

- `lib/app/app_config.dart`
- `lib/app/app_plugins.dart`
- `lib/app/app_features.dart`

이 외의 파일이 두 번째 composition root가 되면 안 된다.

- `app_plugins.dart` 상단: 사용자가 직접 수정하는 provider set / 최소 config 입력
- `app_plugins.dart` 하단: 입력으로부터 계산되는 plugin/runtime 파생값
- `app_features.dart` 상단: 사용자가 직접 수정하는 feature/policy 입력
- `app_features.dart` 하단: 입력으로부터 계산되는 route/redirect/error wiring 파생값

---

## 핵심 원칙

- Engine은 domain-agnostic runtime/routing/shell infrastructure와 abstraction을 소유한다.
- Engine은 app, modules, features의 도메인 의미를 알지 않는다.
- app 설정은 3개 파일로 수렴해야 한다.
- reusable module과 project-specific feature를 구분해서 읽어야 한다.
- `modules/foundation`은 modules/features가 함께 기대는 얇은 공통 기반 타입 위치이며 `AppError`, `Result`가 여기에 있다.
- module은 공개 계약과 설정 표면을 중심으로 노출된다.
- concrete 구현은 module 내부가 소유하고 app은 공개 표면으로 조립한다.
- app은 provider 선택, 최소 config, 정책 입력, route/redirect/error wiring을 조립하는 composition root다.
- `features/common`은 실제 `common.dart`만 가진 project-level shared surface 위치이며 아직 shared asset은 비어 있다.
- `auth_flow`는 `auth_flow.dart` entry를 가진 consumer feature이며 auth module의 공개 표면을 소비한다.
- feature는 module의 공개 표면을 소비하는 consumer slice로 확장된다.
- UI는 ErrorDecision을 기반으로 표현만 수행한다.
- engine은 에러를 해석하지 않는다.

---

## 문서 가이드 (중요)

이 프로젝트는 문서를 기준으로 구조를 이해해야 한다.

아래 순서대로 읽는 것을 권장한다.

### 1. 전체 구조 이해

- `docs/00_KICKOFF.md`
- `docs/01_ARCHITECTURE.md`

→ 프로젝트의 목적과 전체 구조를 이해한다.

---

### 2. 구현 규칙 이해

- `docs/02_CODING_CONTRACT.md`

→ 실제 코드를 어떻게 작성해야 하는지 확인한다.

---

### 3. 라우팅 구조 이해

- `docs/03_ROUTING_GUIDE.md`

→ route DSL과 navigation 흐름을 이해한다.

---

### 4. 에러 처리 구조 이해

- `docs/07_ERROR_POLICY.md`

→ feature failure와 global error의 차이를 이해한다.

---

### 5. 기타 참고 문서

- `docs/04_DECISIONS.md` → 설계 결정 기록
- `docs/05_COMMENT_GUIDE.md` → 주석 작성 기준
- `docs/06_AI_WORKFLOW.md` → AI 협업 규칙
- `docs/08_ADOPTION_MAP.md` → 재사용/확장 후보

---

## 현재 범위에 포함되지 않는 것

다음은 아직 현재 범위에 포함되지 않는다.

- shell 고급 커스터마이징
- route transition / analytics 확장
- push / notification provider set
- role/status 기반 접근 제어
- 소셜 로그인
- shared error / logger core 승격

이 항목들은 이후 Phase에서 도입한다.

---

## 현재 상태 요약

- Phase 3.1: auth 구조 분리 + UX 확장 완료
- Phase 3.2: 전역 에러 처리 시스템 도입 완료
- Phase 3.3: post-login account action(changePassword / deleteAccount) 완료
- Phase 3.4: Session Integrity 완료
- Phase 3.5: AuthSession public contract stabilization 완료
- Phase 3.6: provider set 기반 app composition + auth assembly 정렬 완료

이 상태부터는

👉 **Engine을 수정하지 않고 Feature 추가만으로 앱을 확장할 수 있다.**
