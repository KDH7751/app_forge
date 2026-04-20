import '../../foundation/foundation.dart';
import '../domain/validation/auth_field_keys.dart';

/// feature-level auth failure를 사용자 표현 결과로 바꾸는 presenter 출력.
///
/// 일부 auth failure가 app root 공용 피드백 채널로 전달될 수는 있지만,
/// 이 값은 feature failure 소비 판단일 뿐 global/runtime error 모델 승격이 아니다.
class AuthFailurePresentation {
  const AuthFailurePresentation({
    required this.message,
    required this.disposition,
  });

  final String message;
  final AuthFailurePresentationDisposition disposition;

  bool get isLocalOnly =>
      disposition == AuthFailurePresentationDisposition.localOnly;

  bool get shouldReportToRootFeedback =>
      disposition == AuthFailurePresentationDisposition.rootFeedbackCandidate;
}

/// presenter가 auth failure를 어떤 사용자 피드백 경로로 읽는지 나타낸다.
enum AuthFailurePresentationDisposition { localOnly, rootFeedbackCandidate }

/// auth consumer feature가 정규화된 `AppFailure`를 사용자 표현으로 읽는 진입점.
final class AuthFailurePresenter {
  const AuthFailurePresenter._();

  static AuthFailurePresentation? presentForAuthFlow(Object? failure) {
    return _present(
      failure,
      localTypes: const <AppFailureType>{
        AppFailureType.validation,
        AppFailureType.invalidCredentials,
        AppFailureType.notFound,
        AppFailureType.conflict,
      },
    );
  }

  static AuthFailurePresentation? presentForProfileAction(Object? failure) {
    return _present(
      failure,
      localTypes: const <AppFailureType>{
        AppFailureType.validation,
        AppFailureType.invalidCredentials,
      },
    );
  }

  /// root feedback channel이 auth feature failure를 문구로 읽을 때 사용한다.
  ///
  /// root는 전달된 failure를 표시만 할 뿐,
  /// 이를 global/runtime error 계약으로 재해석하지 않는다.
  static String? messageForRootFeedback(Object? failure) {
    return _messageFor(failure);
  }

  static AuthFailurePresentation? _present(
    Object? failure, {
    required Set<AppFailureType> localTypes,
  }) {
    if (failure is! AppFailure) {
      return null;
    }

    return AuthFailurePresentation(
      message: _messageForAppFailure(failure),
      disposition: localTypes.contains(failure.type)
          ? AuthFailurePresentationDisposition.localOnly
          : AuthFailurePresentationDisposition.rootFeedbackCandidate,
    );
  }

  static String? _messageFor(Object? failure) {
    if (failure is! AppFailure) {
      return null;
    }

    return _messageForAppFailure(failure);
  }

  static String _messageForAppFailure(AppFailure failure) {
    return switch (failure.type) {
      AppFailureType.validation => _mapValidationFailureText(failure),
      AppFailureType.invalidCredentials => '인증 정보가 올바르지 않습니다',
      AppFailureType.unauthorized => '인증이 필요합니다. 다시 로그인해주세요',
      AppFailureType.permissionDenied => '요청을 수행할 권한이 없습니다',
      AppFailureType.notFound => '대상을 찾을 수 없습니다',
      AppFailureType.conflict => '이미 사용 중인 정보입니다',
      AppFailureType.rateLimited => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요',
      AppFailureType.network => '네트워크 문제로 요청을 처리할 수 없습니다',
      AppFailureType.unavailable => '현재 요청을 처리할 수 없습니다. 잠시 후 다시 시도해주세요',
      AppFailureType.unknown => '요청을 처리할 수 없습니다. 다시 시도해주세요',
    };
  }

  static String _mapValidationFailureText(AppFailure failure) {
    if (failure.fieldErrors.length != 1) {
      return '입력값을 확인해주세요';
    }

    final entry = failure.fieldErrors.entries.single;

    return switch (entry.key) {
      AuthFailureField.email => _mapEmailFieldError(entry.value),
      AuthFailureField.password => _mapPasswordFieldError(entry.value),
      AuthFailureField.confirmPassword => _mapConfirmPasswordFieldError(
        entry.value,
      ),
      AuthFailureField.currentPassword => _mapCurrentPasswordFieldError(
        entry.value,
      ),
      AuthFailureField.newPassword => _mapNewPasswordFieldError(entry.value),
      AuthFailureField.confirmNewPassword => _mapConfirmNewPasswordFieldError(
        entry.value,
      ),
      _ => '입력값을 확인해주세요',
    };
  }

  static String _mapEmailFieldError(ValidationFieldError error) {
    return switch (error.type) {
      ValidationFieldErrorType.required => '이메일을 입력해주세요',
      ValidationFieldErrorType.invalid => '올바른 이메일 형식을 입력해주세요',
      _ => '이메일 입력값을 확인해주세요',
    };
  }

  static String _mapPasswordFieldError(ValidationFieldError error) {
    return switch (error.type) {
      ValidationFieldErrorType.required => '비밀번호를 입력해주세요',
      ValidationFieldErrorType.tooWeak => '비밀번호가 너무 약합니다',
      _ => '비밀번호 입력값을 확인해주세요',
    };
  }

  static String _mapConfirmPasswordFieldError(ValidationFieldError error) {
    return switch (error.type) {
      ValidationFieldErrorType.required => '비밀번호 확인을 입력해주세요',
      ValidationFieldErrorType.mismatch => '비밀번호가 일치하지 않습니다',
      _ => '비밀번호 확인 입력값을 확인해주세요',
    };
  }

  static String _mapCurrentPasswordFieldError(ValidationFieldError error) {
    return switch (error.type) {
      ValidationFieldErrorType.required => '현재 비밀번호를 입력해주세요',
      _ => '현재 비밀번호 입력값을 확인해주세요',
    };
  }

  static String _mapNewPasswordFieldError(ValidationFieldError error) {
    return switch (error.type) {
      ValidationFieldErrorType.required => '새 비밀번호를 입력해주세요',
      ValidationFieldErrorType.tooWeak => '새 비밀번호가 너무 약합니다',
      ValidationFieldErrorType.sameValue => '현재 비밀번호와 다른 새 비밀번호를 입력해주세요',
      _ => '새 비밀번호 입력값을 확인해주세요',
    };
  }

  static String _mapConfirmNewPasswordFieldError(ValidationFieldError error) {
    return switch (error.type) {
      ValidationFieldErrorType.required => '새 비밀번호 확인을 입력해주세요',
      ValidationFieldErrorType.mismatch => '비밀번호가 일치하지 않습니다',
      _ => '새 비밀번호 확인 입력값을 확인해주세요',
    };
  }
}
