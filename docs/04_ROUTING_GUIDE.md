# Routing Guide

## 방향

장기적으로 Routing 시스템은 Engine이 소유하는 route DSL과 app이 주입하는 policy를 기반으로 동작해야 한다.

Engine Router는 auth를 직접 알면 안 된다.
실제 Router Engine이 도입될 때 redirect policy는 app이 주입한다.

## Phase 1 범위

Phase 1에서는 실제 Router Engine을 구현하지 않는다.

Phase 1에서 제공하는 범위는 다음과 같다.

- 필요한 경우 사용할 placeholder Routing 계약
- app이 컴파일되도록 만드는 placeholder page
- 이후 Router 작업의 소유권을 설명하는 문서

Phase 2에서는 다음을 구현한다.

- `RouteDef`
- Router tree composition
- navigation state
- shell-aware route metadata
- 주입 가능한 redirect/auth gate policy

## 반드시 지킬 규칙

- Router Engine은 auth Feature를 import하지 않는다.
- redirect policy 주입 책임은 app이 가진다.
- shell 노출 여부는 page별 하드코딩이 아니라 route metadata에서 파생되어야 한다.
