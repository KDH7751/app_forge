# Coding Contract

## Intent

This document fixes the coding rules so generated code stays consistent across
phases and across contributors.

## Work Unit

- Implement in vertical slices.
- Change files in batches of 3 to 5 whenever practical.
- Define or confirm public API first, then fill implementation.

## Layer Rules

- `presentation/`: widgets, view state mapping, user interaction
- `domain/`: entities and business rules owned by the feature
- `data/`: repository and datasource implementations
- Firebase calls are allowed only under `features/**/data/**`

UI must never call Firebase directly.

## Dependency Direction

- features may depend on `lib/engine/engine.dart`
- app may depend on `lib/engine/engine.dart` and features
- engine must not depend on app or features

Inside this repository, app and features import
`package:app_forge/engine/engine.dart`. That package path is the only allowed
public engine surface for runtime code.

## Async and Error Rules

- All async feature-facing operations return `Result<T>`
- Do not throw raw `FirebaseException`, parser errors, or transport errors
- Map external failures into `AppError`
- UI handles only `AppError`

## Provider Rules

- Riverpod is the default DI mechanism
- Provider names should end with `Provider`
- Keep provider ownership close to the slice that uses it
- Avoid global service locators

## Naming Rules

- file names: `snake_case.dart`
- types: `PascalCase`
- providers: descriptive `camelCaseProvider`
- placeholders should be named explicitly as placeholders when not final

## Engine Exposure Rule

- `package:app_forge/engine/engine.dart` is the only file app/features should
  import from engine
- `lib/engine/src/**` is internal and may change without notice
