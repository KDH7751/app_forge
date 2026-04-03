import 'error_models.dart';

/// ===================================================================
/// ErrorPolicy
///
/// 역할:
/// - ErrorEnvelope를 처리 결정값으로 변환하는 policy contract를 정의한다.
///
/// 결정:
/// - 어떤 에러를 log / notify 할지와 어느 severity로 볼지가 이 contract 구현에서 정해진다.
///
/// 주의:
/// - ErrorEnvelope를 수정하지 않는다.
/// - 로깅이나 UI 전달을 직접 수행하지 않고 결정값만 반환한다.
/// ===================================================================
abstract class ErrorPolicy {
  /// 단일 ErrorEnvelope를 ErrorDecision으로 변환한다.
  ///
  /// ErrorHub는 모든 전역 에러에 대해 이 메서드를 호출하고,
  /// 반환된 결정값을 기준으로 logger 호출과 stream 이벤트를 진행한다.
  ErrorDecision decide(ErrorEnvelope error);
}
