// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Bootstrap Module Public Entry
///
/// 역할:
/// - bootstrap module의 외부 소비 진입점을 한 곳으로 모은다.
///
/// 경계:
/// - app 설정 source of truth를 새로 만들지 않는다.
/// - host/runtime 구현 세부는 내부 파일로 분리해 유지한다.
/// ===================================================================

export 'bootstrap_host.dart' show Bootstrap;
export 'bootstrap_runtime.dart' show runAppWithErrorHandling;
