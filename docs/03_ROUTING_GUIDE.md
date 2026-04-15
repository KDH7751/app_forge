# Routing Guide

## 방향

Routing 시스템은 Engine이 소유하는 route DSL과
app이 조립하는 route registration을 기반으로 동작한다.

앱 전체 구조와 레이어 경계는 `docs/01_ARCHITECTURE.md`를 따른다.

Engine Router는 auth를 직접 알면 안 된다.
redirect policy가 필요해지면 그 책임은 app이 가진다.
auth entry page는 project-level auth consumer feature가 소유하고, auth module은 그 기능을 지원만 한다.

## 현재 범위

현재 라우팅 시스템은 다음을 포함한다.

- `RouteDef`
- route tree composition
- location 기반 route matching
- `NavigationState`
- `RouterEngine`
- `EngineShell`
- `FeatureShell`
- app-defined auth redirect
- `refreshListenable` 기반 redirect 재평가

다음은 아직 포함하지 않는다.

- role/status 기반 protected route 정책
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

redirect 재평가는 `refreshListenable`로만 트리거한다.
provider나 Firebase 상태는 app layer가 `Listenable`로 bridge해서 RouterEngine에 주입한다.

## shell 규칙

shell은 공통 Scaffold 기반 컨테이너다.

shell 내부 route는 metadata로 제어한다.

- `useShell`
- `showAppBar`
- `showBottomNav`
- `showDrawer`

예:
- `/login`: `useShell: false`
- `/signup`: `useShell: false`
- `/reset-password`: `useShell: false`
- `/home`: shell + bottomNav
- `/profile`: shell + drawer
- `/posts/:id`: shell 내부 detail, bottomNav/drawer 숨김

`/login`, `/signup`, `/reset-password` route는 auth_flow feature entry(`auth_flow.dart`)가 노출하는 page를 렌더링한다.
auth_flow feature는 auth module의 공개 표면만 소비하지만 redirect는 직접 처리하지 않는다.

## redirect 규칙

- redirect 판단 책임은 app layer가 가진다.
- RouterEngine은 redirect callback과 `refreshListenable`만 소비한다.
- redirect는 인증 상태와 현재 location을 기준으로 판단한다.
- redirect는 에러를 해석하거나 UI를 제어하는 책임을 가지지 않는다.
- redirect는 internal flag가 아니라 최종 `AuthSession` public contract만 소비한다.
- invalid session 차단도 app layer redirect 판단에 포함되며, RouterEngine이 auth policy를 직접 해석하지 않는다.
- bootstrap module은 auth session observation 변화를 `refreshListenable`로 bridge하는 runtime wiring만 담당한다.
- `Authenticated`는 보호 라우트를 허용한다.
- `Unauthenticated`는 public auth entry로 보낸다.
- `Invalid`는 public auth entry로 이탈시키고 강제 logout 흐름과 연결된다.
- `Pending`은 placeholder 대기 상태로 두고 목적지 확정을 보류한다.
- observation `AsyncError`는 `Unauthenticated`로 강등하지 않고 `Pending`으로 유지한다.
- invalid 감지 시 보호 라우트는 즉시 public auth entry로 이탈하며, signOut 완료를 기다리지 않는다.
- login/signup 직후 첫 `users/{uid}` 확인 전에는 pending 구간이 있을 수 있지만, 이 구간은 보호 라우트 허용 완화가 아니라 placeholder 대기 상태로 처리한다.

## EngineFeature와 route 등록

app은 Engine route contract를 사용해 Feature route tree를 조립한다.

- `appRouteTrees`: GoRouter tree 구성용
- `appRoutes`: matcher / currentRoute 판별용

engine naming은 개념 기반 이름을 유지한다.
feature layer naming 규칙을 `route_def`, `router_engine`, `navigation_state` 같은 engine 파일에 적용하지 않는다.

## FeatureShell 규칙

FeatureShell은 화면 상태 wrapper다.

현재 범위에서 다음을 제공한다.

- loading
- error
- data
