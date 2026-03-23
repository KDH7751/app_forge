# Flutter App Engine Template

## Purpose

This repository is not for shipping a single toy app.

The goal is to build a reusable Flutter app engine template that can be copied
into new projects and extended by adding features.

The intended usage is:

1. Start from this template structure.
2. Configure only three app entry points:
   - `lib/app/app_config.dart`
   - `lib/app/app_plugins.dart`
   - `lib/app/app_features.dart`
3. Build product behavior by adding or editing code only under `lib/features/`.

## Core Principles

- Engine does not know app or features.
- App config lives in three places only.
- Features should be enough to extend the app.
- Engine holds policy, flow, and abstractions; concrete implementations are
  injected by app.
- App is the composition root for engine, plugins, and features.
- Each feature is a complete vertical slice with domain, data, and presentation.

## Target Structure

```text
lib/
  engine/      # reusable engine layer
  ui_kit/      # reusable UI primitives and tokens
  main.dart
  app/         # composition root for this app
  features/    # product features
```

## Fixed Stack

- Flutter + Dart
- Riverpod
- go_router
- freezed + json_serializable
- Firebase Auth / Firestore / FCM / Crashlytics

## Non-Goals

- Implementing full product features before the engine boundary is fixed
- Allowing direct Firebase calls from UI
- Hard-coding auth policy inside the router engine

## Phase 1 Scope

Phase 1 only fixes structure, boundaries, public API, and placeholder bootstrap.
Actual router implementation, Firebase integration, login, and community
features start in later phases.

## Documents

- `docs/01_ARCHITECTURE.md`: structure and dependency rules
- `docs/02_CODING_CONTRACT.md`: coding rules and layer contracts
- `docs/04_ROUTING_GUIDE.md`: routing direction and Phase 1 placeholder scope
