# Routing Guide

## Direction

The long-term routing system will use an engine-owned route DSL and app-injected
policy.

The engine router must not know auth directly. Redirect policy will be injected
by app when the real router engine is introduced.

## Phase 1 Scope

Phase 1 does not implement the real router engine.

Phase 1 only provides:

- placeholder routing contracts if needed
- placeholder pages so the app compiles
- documented ownership for future router work

Phase 2 will implement:

- `RouteDef`
- router tree composition
- navigation state
- shell-aware route metadata
- injected redirect/auth gate policy

## Non-Negotiable Rules

- router engine does not import auth feature
- app owns redirect policy injection
- shell visibility is derived from route metadata, not hard-coded per page
