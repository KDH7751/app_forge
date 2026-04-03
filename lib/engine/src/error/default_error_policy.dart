import 'error_models.dart';
import 'error_policy.dart';

/// 기본적인 source/domain 존재 여부만으로 처리 강도를 정한다.
///
/// app 전역 기본값일 뿐이며,
/// 실제 UX 요구사항이 생기면 app layer에서 override해야 한다.
class DefaultErrorPolicy implements ErrorPolicy {
  const DefaultErrorPolicy();

  @override
  ErrorDecision decide(ErrorEnvelope error) {
    switch (error.source) {
      case ErrorSource.platform:
        return const ErrorDecision(
          shouldLog: true,
          shouldNotify: false,
          severity: ErrorSeverity.fatal,
        );
      case ErrorSource.framework:
        return const ErrorDecision(
          shouldLog: true,
          shouldNotify: false,
          severity: ErrorSeverity.error,
        );
      case ErrorSource.async:
        return ErrorDecision(
          shouldLog: true,
          shouldNotify: error.domainError != null,
          severity: error.domainError != null
              ? ErrorSeverity.warning
              : ErrorSeverity.error,
        );
      case ErrorSource.ui:
        return ErrorDecision(
          shouldLog: true,
          shouldNotify: error.domainError != null,
          severity: error.domainError != null
              ? ErrorSeverity.warning
              : ErrorSeverity.error,
        );
      case ErrorSource.unknown:
        return const ErrorDecision(
          shouldLog: true,
          shouldNotify: false,
          severity: ErrorSeverity.error,
        );
    }
  }
}
