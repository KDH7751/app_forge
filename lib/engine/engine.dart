// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Public API
///
/// 역할:
/// - app과 Feature가 사용하는 유일한 Engine surface 제공.
///
/// 경계:
/// - `lib/engine/src/**` 내부 구현은 외부에 노출하지 않음.
/// - app/Feature 전용 구현은 여기서 공개하지 않음.
/// ===================================================================

export 'src/bootstrap/engine_plugin.dart';
export 'src/routing/engine_feature.dart';
export 'src/routing/navigation_state.dart';
export 'src/routing/route_def.dart';
export 'src/routing/route_matcher.dart';
export 'src/routing/router_engine.dart';
export 'src/shell/engine_shell.dart';
export 'src/shell/feature_shell.dart';
