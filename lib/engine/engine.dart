// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Public Surface
///
/// app과 feature가 사용하는 engine의 유일한 import 경로.
///
/// engine 내부 구현(src/**)은 직접 접근하지 않고,
/// 이 파일을 통해 필요한 contract만 사용해야 한다.
///
/// 주의:
/// - public contract만 노출해야 한다.
/// - 내부 구현 세부사항을 외부로 확장하지 않는다.
/// ===================================================================

export 'src/plugins/engine_plugin.dart';
export 'src/error/default_error_policy.dart';
export 'src/error/error_hub.dart';
export 'src/error/error_models.dart';
export 'src/error/error_policy.dart';
export 'src/error/logger.dart';
export 'src/routing/engine_feature.dart';
export 'src/routing/navigation_state.dart';
export 'src/routing/route_def.dart';
export 'src/routing/route_matcher.dart';
export 'src/routing/router_engine.dart';
export 'src/shell/engine_shell.dart';
export 'src/shell/feature_shell.dart';
