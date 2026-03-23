# AI Workflow

## Default Sequence

1. inspect current code and documents
2. confirm or define public API
3. implement in 3 to 5 file batches
4. verify formatting, analysis, and tests

## Required Output

- intent of the change
- changed files
- one-line responsibility per file
- dependency-rule compliance note
- next checklist

## Forbidden Patterns

- direct Firebase calls from UI
- raw throw-based async flows
- engine importing app or features
