// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Feedback Module Public Surface
///
/// 역할:
/// - app, bootstrap, feature, 다른 module이 3.8 feedback contract를
///   같은 경로로 소비하게 한다.
///
/// 경계:
/// - 이번 phase에 잠근 feedback contract와 root display wiring만 노출한다.
/// - 범용 확장을 선행해서 public surface를 넓히지 않는다.
/// ===================================================================

export 'domain/feedback_preset.dart';
export 'domain/feedback_request.dart';
export 'domain/feedback_slots.dart';
export 'state/feedback_dispatcher.dart';
export 'state/feedback_provider.dart';
export 'ui/feedback_host.dart';
