// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Public API
///
/// 역할:
/// - app과 Feature가 사용할 유일한 Engine surface를 노출한다
///
/// 책임:
/// - runtime code가 사용할 안정적인 Engine 계약만 다시 노출한다
///
/// 경계:
/// - 외부 import에서 `lib/engine/src/**`를 숨긴다
/// - Feature 전용 구현이나 app 전용 구현은 노출하지 않는다
///
/// 의존성:
/// - Engine이 소유한 계약만 다시 노출한다
/// ===================================================================

export 'src/bootstrap/engine_plugin.dart';
export 'src/routing/engine_feature.dart';
export 'src/shell/engine_placeholder_shell.dart';
