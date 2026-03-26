# Routing Guide

## 방향

Routing 시스템은 Engine이 소유하는 route DSL과
app이 조립하는 route registration을 기반으로 동작한다.

Engine Router는 auth를 직접 알면 안 된다.
redirect policy가 필요해지면 그 책임은 app이 가진다.

## 현재 범위

현재 라우팅 시스템은 다음을 포함한다.

- `RouteDef`
- route tree composition
- location 기반 route matching
- `NavigationState`
- `RouterEngine`
- `EngineShell`
- `FeatureShell`

다음은 아직 포함하지 않는다.

- auth redirect policy
- protected route 정책
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

예:
- `/posts`
- `/posts/:id`
- `/posts/new`

## route matching 규칙

matching 우선순위는 다음과 같다.

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

NavigationState 갱신은 RouterEngine의 단일 sync 지점이 소유한다.

- redirect 안에서 상태를 갱신하지 않는다
- widget build 중 임의로 상태를 sync하지 않는다
- post frame / microtask 같은 우회성 갱신에 기대지 않는다

## shell 규칙

shell은 공통 Scaffold 기반 컨테이너다.

shell 내부 route는 metadata로 제어한다.

- `useShell`
- `showAppBar`
- `showBottomNav`
- `showDrawer`

예:
- `/login`: `useShell: false`
- `/home`: shell + bottomNav
- `/profile`: shell + drawer
- `/posts/:id`: shell 내부 detail, bottomNav/drawer 숨김

## EngineFeature와 route 등록

app은 Engine route contract를 사용해 Feature route tree를 조립한다.

- `appRouteTrees`: GoRouter tree 구성용
- `appRoutes`: matcher / currentRoute 판별용

## FeatureShell 규칙

FeatureShell은 화면 상태 wrapper다.

현재 범위에서 다음을 제공한다.

- loading
- error
- data