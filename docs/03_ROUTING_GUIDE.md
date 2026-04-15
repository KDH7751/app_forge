# Routing Guide

## 목적

이 문서는 routing DSL, RouterEngine, NavigationState, shell 규칙을 정리한다.
구조 경계와 일반 구현 규칙은 `docs/01_ARCHITECTURE.md`, `docs/02_CODING_CONTRACT.md`를 따른다.

## 현재 범위

현재 라우팅 시스템은 다음을 포함한다.

- `RouteDef`
- route tree composition
- location 기반 route matching
- `NavigationState`
- `RouterEngine`
- `EngineShell`
- `FeatureShell`
- app-defined redirect
- `refreshListenable` 기반 redirect 재평가

현재 범위에 포함하지 않는 것:

- role/status 기반 protected route 정책 확장
- route transition 확장
- analytics metadata
- route-level business policy

## Route DSL 규칙

Route는 `RouteDef` 또는 동등한 DSL로 정의한다.

필수 필드:

- `path`
- `name`
- `builder`

선택 필드:

- `children`
- `useShell`
- `showAppBar`
- `showBottomNav`
- `showDrawer`
- `icon`
- `label`

`builder`는 `(BuildContext, GoRouterState)` 시그니처를 사용한다.

## path / nested 규칙

- `RouteDef.path`는 top-level과 child 모두 절대경로를 source of truth로 유지한다.
- child route도 전체 경로를 가진다.
- GoRouter용 상대경로 변환은 Engine 내부 구현에서만 수행한다.
- nested 구조는 `children`으로만 표현한다.
- `parent` 필드는 사용하지 않는다.

## route matching 규칙

matching 우선순위:

1. 정확 path 매칭
2. param path 매칭
3. 더 긴 path 우선

query parameter는 route matching 기준이 아니다.

## NavigationState 규칙

NavigationState는 원시 상태만 가진다.

포함 필드:

- `location`
- `currentRoute`
- `pathParams`
- `queryParams`
- `extra`

포함하지 않는 값:

- bottom nav index
- resolved title
- drawer 열림 여부
- analytics metadata
- redirect reason

## navigation sync 규칙

- NavigationState 갱신은 RouterEngine의 단일 sync 지점이 소유한다.
- redirect 안에서 상태를 갱신하지 않는다.
- widget build 중 임의로 상태를 sync하지 않는다.
- post frame / microtask 같은 우회성 갱신에 기대지 않는다.

redirect 재평가는 `refreshListenable`로만 트리거한다.

## shell 규칙

shell은 공통 Scaffold 기반 컨테이너다.
shell 내부 route는 아래 metadata로 제어한다.

- `useShell`
- `showAppBar`
- `showBottomNav`
- `showDrawer`

public auth entry route처럼 shell 밖에 있어야 하는 화면은 `useShell: false`로 둔다.

## redirect 규칙

- redirect 판단 책임은 app layer가 가진다.
- RouterEngine은 redirect callback과 `refreshListenable`만 소비한다.
- redirect는 현재 location과 app이 넘긴 최종 상태만 기준으로 판단한다.
- redirect는 에러 해석, UI 제어, domain policy 소유권을 가지지 않는다.

## route 등록 규칙

app은 Engine route contract를 사용해 feature route tree를 조립한다.

- `appRouteTrees`: GoRouter tree 구성용
- `appRoutes`: matcher / currentRoute 판별용

## FeatureShell 규칙

FeatureShell은 화면 상태 wrapper다.

현재 범위:

- loading
- error
- data
