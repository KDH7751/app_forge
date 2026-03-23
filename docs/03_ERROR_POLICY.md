# Error Policy

## Rule

Feature-facing async APIs return `Result<T>`.

External exceptions must be mapped into `AppError` before leaving data and
repository layers.

## Minimum Categories

- auth
- permission
- notFound
- network
- parsing
- unknown

## UI Policy

UI handles `AppError` only.

Detailed error presentation patterns will be introduced with feature shell and
router work in later phases.
