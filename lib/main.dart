// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Main Runtime Entry
///
/// 역할:
/// - runtime bootstrap helper 진입점만 제공.
///
/// 경계:
/// - app 설정 source of truth를 만들지 않음.
/// - zone/error/plugin orchestration은 bootstrap layer로 위임함.
/// ===================================================================

import 'bootstrap/bootstrap.dart';
import 'bootstrap/bootstrap_runtime.dart';

/// runtime 시작 진입점.
void main() {
  runAppWithErrorHandling((errorHub) => Bootstrap(errorHub: errorHub));
}
