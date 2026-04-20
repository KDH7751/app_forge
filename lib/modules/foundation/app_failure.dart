/// 여러 module과 feature가 함께 사용할 수 있는 최소 실패 타입.
enum AppFailureType {
  validation,
  invalidCredentials,
  unauthorized,
  permissionDenied,
  notFound,
  conflict,
  rateLimited,
  network,
  unavailable,
  unknown,
}

/// validation failure가 필드 단위로 노출할 수 있는 최소 의미 타입.
enum ValidationFieldErrorType {
  required,
  invalid,
  mismatch,
  tooWeak,
  sameValue,
}

/// validation field error 하나를 표현하는 얇은 공통 계약.
class ValidationFieldError {
  const ValidationFieldError._(this.type);

  final ValidationFieldErrorType type;

  static const ValidationFieldError required = ValidationFieldError._(
    ValidationFieldErrorType.required,
  );

  static const ValidationFieldError invalid = ValidationFieldError._(
    ValidationFieldErrorType.invalid,
  );

  static const ValidationFieldError mismatch = ValidationFieldError._(
    ValidationFieldErrorType.mismatch,
  );

  static const ValidationFieldError tooWeak = ValidationFieldError._(
    ValidationFieldErrorType.tooWeak,
  );

  static const ValidationFieldError sameValue = ValidationFieldError._(
    ValidationFieldErrorType.sameValue,
  );
}

/// modules/features가 함께 기대는 얇은 공통 기반 AppFailure 모델.
class AppFailure {
  const AppFailure._({
    required this.type,
    this.fieldErrors = const <String, ValidationFieldError>{},
  });

  const AppFailure.validation({
    required Map<String, ValidationFieldError> fieldErrors,
  }) : this._(type: AppFailureType.validation, fieldErrors: fieldErrors);

  final AppFailureType type;
  final Map<String, ValidationFieldError> fieldErrors;

  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  ValidationFieldError? fieldError(String field) {
    return fieldErrors[field];
  }

  AppFailure? fieldFailure(String field) {
    final fieldError = fieldErrors[field];

    if (fieldError == null) {
      return null;
    }

    return AppFailure.validation(
      fieldErrors: <String, ValidationFieldError>{field: fieldError},
    );
  }

  static const AppFailure invalidCredentials = AppFailure._(
    type: AppFailureType.invalidCredentials,
  );

  static const AppFailure unauthorized = AppFailure._(
    type: AppFailureType.unauthorized,
  );

  static const AppFailure permissionDenied = AppFailure._(
    type: AppFailureType.permissionDenied,
  );

  static const AppFailure notFound = AppFailure._(
    type: AppFailureType.notFound,
  );

  static const AppFailure conflict = AppFailure._(
    type: AppFailureType.conflict,
  );

  static const AppFailure rateLimited = AppFailure._(
    type: AppFailureType.rateLimited,
  );

  static const AppFailure network = AppFailure._(type: AppFailureType.network);

  static const AppFailure unavailable = AppFailure._(
    type: AppFailureType.unavailable,
  );

  static const AppFailure unknown = AppFailure._(type: AppFailureType.unknown);
}
