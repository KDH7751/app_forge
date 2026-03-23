# Decisions

- 2026-03-23: Engine은 policy, flow, abstraction을 소유하고 concrete 구현은 재사용성을 위해 app이 주입한다.
- 2026-03-23: app은 Engine, Plugin, Feature를 조립하는 composition root다.
- 2026-03-23: Feature는 domain, data, presentation을 함께 가지는 vertical slice로 유지한다.
- 2026-03-23: app과 Feature의 유일한 public Engine import 경로는 `package:app_forge/engine/engine.dart`다.
- 2026-03-23: Phase 1에서는 placeholder bootstrap과 placeholder page만 두고 Router 구현은 Phase 2로 미룬다.
