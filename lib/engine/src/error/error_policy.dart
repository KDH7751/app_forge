import 'error_models.dart';

/// ErrorEnvelope를 처리 결정값으로 변환하는 policy 계약.
abstract class ErrorPolicy {
  ErrorDecision decide(ErrorEnvelope error);
}
