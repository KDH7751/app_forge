# Architecture

## Objective

This template separates reusable engine infrastructure from app composition and
feature implementation.

The boundary is strict:

- `lib/engine/` contains policy, flow, abstractions, and reusable engine widgets.
- `app/` composes engine, plugins, and registered features.
- `features/` contains product functionality as vertical slices.

## Final Tree

```text
lib/
  main.dart
  engine/
    engine.dart
    src/
      bootstrap/
      routing/
      shell/
  app/
    app_config.dart
    app_plugins.dart
    app_features.dart
  features/
    home/
      presentation/
    settings/
      presentation/
  ui_kit/
```

## Folder Responsibilities

- `lib/engine/`: reusable engine surface and internal engine implementation
- `lib/engine/src/bootstrap`: app bootstrapping contracts used by the composition root
- `lib/engine/src/routing`: routing abstractions and placeholders for Phase 1
- `lib/engine/src/shell`: reusable app shell placeholders owned by the engine
- `lib/ui_kit/`: shared UI tokens and widgets that can be reused across apps
- `lib/app/`: the app composition root and the only app-specific configuration
- `lib/features/`: feature modules built as vertical slices
- `lib/features/**/presentation`: feature UI and presentation state

## Three App Configuration Files

App-specific setup must converge into these files only:

- `app_config.dart`: app look and feel, initial route intent, root builders
- `app_plugins.dart`: plugin assembly and runtime integrations
- `app_features.dart`: feature registration list exposed to the app

No other file should become a second composition root.

## Import Rules

Allowed:

- `lib/features/**` -> `package:app_forge/engine/engine.dart`
- `lib/app/**` -> `package:app_forge/engine/engine.dart`
- `lib/app/**` -> `lib/features/**`
- feature presentation -> feature domain/data within the same slice

Forbidden:

- `lib/engine/**` -> `lib/features/**`
- `lib/engine/**` -> `lib/app/**`
- router code -> auth feature directly
- UI widgets/pages -> Firebase SDK directly
- arbitrary global singletons as cross-layer dependency wiring
- `lib/app/**` or `lib/features/**` importing `lib/engine/src/**` directly

## Composition Model

- Engine defines contracts and reusable flow.
- App provides concrete composition and policy injection.
- Features provide user-facing behavior and route/page registrations.

This keeps the engine reusable and prevents domain policy from leaking inward.
