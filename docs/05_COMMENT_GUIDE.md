# Comment Guide

## 목적

주석은 코드를 장식하는 문장이 아니라, 선언의 실제 역할과 수정 영향을 빠르게 이해하게 만드는 설명이어야 한다.

## 빠른 기준

- engine → 구조 / 흐름 / policy 설명
- app → 전역 영향 설명
- bootstrap → public entry / host / runtime wiring 설명

- Level 1 → 앱 전체 영향 또는 핵심 흐름이 드러나야 하는 경우
- Level 2 → 역할 + 사용 위치가 보이면 되는 경우
- Level 3 → 이름으로 충분한 경우

## 기본 원칙

- 코드 이름을 번역하지 말고 실제 쓰임새와 연결 지점을 설명한다.
- docs의 구조 설명을 복사하지 말고, 이 선언을 읽는 사람에게 필요한 사용 설명을 적는다.
- 오래 유지될 정보만 남기고 수정 영향이 큰 선언은 영향 범위를 분명히 적는다.

## 주석 밀도 레벨

### Level 1

구조적으로 중요하거나 수정 영향이 큰 파일에 적용한다.

- composition root (`app_config.dart`, `app_features.dart`, `app_plugins.dart`)
- engine core (`ErrorHub`, `RouterEngine` 등)
- policy / decision / contract
- redirect / routing 핵심 로직
- plugin wiring
- repository / datasource 핵심 파일

Level 1 파일에서는 아래가 보여야 한다.

- 이 파일이 담당하는 핵심 기능
- 이 파일에서 결정되는 것
- 수정 시 주의할 점

app 주석은 내부 구현보다 전역 영향에 초점을 두고,
bootstrap 주석은 public entry와 host/runtime wiring 경계를 흐리지 않으면서 실행 흐름을 설명한다.

### Level 2

일반적인 로직 파일에 적용한다.

- controller
- provider
- repository
- mapper
- helper
- 일반 state 흐름 코드

1~3줄 정도로 무엇을 하는지와 어디서 쓰이는지 정도를 설명한다.

### Level 3

역할이 비교적 단순한 코드에 적용한다.

- UI widget
- DTO
- 단순 state holder
- 단순 model / enum

이름으로 충분하면 주석을 생략할 수 있다.

## 파일 상단 주석 규칙

- 모든 파일에 같은 길이의 주석을 강제하지 않는다.
- Level 1 파일에는 강한 헤더를 둔다.
- 라벨형을 쓴다면 `역할:` / `결정:` / `주의:` 구성을 기본으로 사용한다.
- page, widget, dto, mapper, 단순 state holder는 짧은 주석 또는 생략으로 충분할 수 있다.

예:

```dart
/// ===================================================================
/// RouterEngine
///
/// 역할:
/// - RouteDef tree를 GoRouter로 변환한다.
///
/// 결정:
/// - route tree가 실제 router 설정으로 바뀌는 방식이 여기서 정해진다.
///
/// 주의:
/// - auth policy를 직접 알지 않는다.
/// ===================================================================
```

bootstrap 계열도 같은 방식으로 public entry와 내부 구현 경계를 드러낸다.

```dart
/// ===================================================================
/// Bootstrap Runtime
///
/// 역할:
/// - app runtime을 단일 zone과 ErrorHub로 시작한다.
///
/// 주의:
/// - bootstrap public entry가 아니라 runtime wiring 구현 파일이다.
/// ===================================================================
```

## 선언 단위 주석 규칙

- 클래스와 함수는 이름만으로 역할이 충분하지 않으면 주석을 둔다.
- 구조적으로 중요하거나 수정 영향이 크면 짧게라도 설명한다.
- 클래스는 책임, 소비 위치, 수정 영향을 적는다.
- 함수는 입력, 결정, 호출 효과를 적는다.

특히 다음 선언은 이름만으로 직관적이지 않으면 보강한다.

- mapper
- policy
- provider
- helper
- aggregation 함수
- route / redirect 관련 함수
- plugin 초기화 함수

예:

```dart
/// app 시작 전 plugin 초기화를 수행한다.
///
/// 초기화 순서가 바뀌면 app 전역 시작 흐름에 영향이 간다.
Future<void> initializeAppPlugins() async { ... }
```

```dart
/// profile route의 임시 account action 섹션.
class ChangePasswordSection extends ConsumerStatefulWidget { ... }
```

## 변수 / 필드 주석 규칙

- 역할이 즉시 보이지 않으면 주석을 둔다.
- composition root 값, policy 조합, route 집계 결과, mapper 목록처럼 실제 입력을 드러내는 값은 주석을 보강한다.
- 이름을 다시 읽어주기보다 소비 지점이나 수정 영향을 적는다.

## docs와 code comment의 역할 구분

- docs는 구조, layer 규칙, 설계 결정, 큰 흐름을 설명한다.
- code comment는 파일/선언을 바로 읽는 사람을 위한 사용 설명이어야 한다.

## 언어 규칙

- 코드 식별자 관련 용어는 영어로 유지한다.
- 설명 문장은 한글로 작성한다.
- 구조와 아키텍처 키워드는 영어로 유지한다.
