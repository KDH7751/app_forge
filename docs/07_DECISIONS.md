# Decisions

- 2026-03-23: Engine owns policy, flow, and abstractions; app injects concrete implementation for reuse.
- 2026-03-23: App is the composition root that assembles engine, plugins, and features.
- 2026-03-23: Features are vertical slices that keep domain, data, and presentation together.
- 2026-03-23: `package:app_forge/engine/engine.dart` is the only public engine import target for app and features.
- 2026-03-23: Phase 1 uses placeholder bootstrapping and placeholder pages; router implementation moves to Phase 2.
