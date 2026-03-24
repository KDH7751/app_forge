# Routing Guide

## 방향

장기적으로 Routing 시스템은 Engine이 소유하는 route DSL과 app이 주입하는 policy를 기반으로 동작해야 한다.

Engine Router는 auth를 직접 알면 안 된다.
redirect policy가 필요해지면 그 책임은 app이 가진다.

## Phase 2 상태

현재 Phase 2에서 제공하는 범위는 다음과 같다.

- `RouteDef`
- Router tree composition
- navigation state
- location 기반 route matching
- shell-aware route metadata
- `EngineShell`
- `FeatureShell`

## 반드시 지킬 규칙

- Router Engine은 auth Feature를 import하지 않는다.
- redirect policy는 이번 단계에 구현하지 않는다.
- shell 노출 여부는 page별 하드코딩이 아니라 route metadata에서 파생되어야 한다.
- `RouteDef.path`는 top-level과 child 모두 절대경로를 source of truth로 유지한다.
- GoRouter용 상대경로 변환은 Engine 내부 구현에서만 수행한다.
- NavigationState는 `location`, `currentRoute`, `pathParams`, `queryParams`, `extra`만 가진다.
- NavigationState 갱신은 RouterEngine 한 지점에서만 수행한다.
