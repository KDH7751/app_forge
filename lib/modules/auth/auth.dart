// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Auth Module Public Surface
///
/// app, bootstrap module, consumer feature는 이 파일을 통해
/// auth module의 공개 계약과 설정 표면만 사용한다.
///
/// 주의:
/// - provider-specific concrete 구현과 assembly 세부는 export하지 않는다.
/// - consumer는 이 파일을 우선 import하고 internal 경로 직접 접근을 줄인다.
/// ===================================================================

export 'domain/auth_facade.dart';
export '../foundation/foundation.dart';
export 'domain/models/change_password_input.dart';
export 'domain/models/delete_account_input.dart';
export 'domain/session/auth_session.dart';
export 'domain/validation/auth_field_keys.dart';
export 'domain/validation/auth_validation.dart';
export 'state/auth_failure_presenter.dart';
export 'state/auth_feedback_coordinator.dart';
export 'state/controllers/change_password_controller.dart';
export 'state/controllers/delete_account_controller.dart';
export 'state/controllers/logout_controller.dart';
export 'state/providers/auth_facade_provider.dart';
export 'state/providers/auth_session_models.dart';
export 'state/providers/auth_session_provider.dart';
export 'state/providers/auth_setup_provider.dart';
