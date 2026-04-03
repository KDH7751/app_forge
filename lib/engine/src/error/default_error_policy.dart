import 'error_models.dart';
import 'error_policy.dart';

/// ===================================================================
/// DefaultErrorPolicy
///
/// 역할:
/// - ErrorSource와 domainError 존재 여부를 기준으로 기본 ErrorDecision을 계산한다.
///
/// 결정:
/// - source별 기본 severity, log 여부, notify 여부가 여기서 정해진다.
///
/// 주의:
/// - domainError의 구체 의미를 해석하지 않는다.
/// - 환경별 표시 방식은 다루지 않고 공통 기본값만 제공한다.
/// ===================================================================
class DefaultErrorPolicy implements ErrorPolicy {
  const DefaultErrorPolicy();

  @override
  /// source와 domainError 존재 여부를 기준으로 기본 처리 강도를 결정한다.
  ///
  /// ErrorHub는 별도 policy 구현이 없을 때 이 판단 결과를 그대로 사용해
  /// 로그 출력과 사용자 알림 여부를 결정한다.
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
