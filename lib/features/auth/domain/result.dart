import 'app_error.dart';

/// auth slice 내부 임시 generic core Result 계약.
sealed class Result<T> {
  const Result();

  /// 성공 결과 생성.
  const factory Result.success(T value) = Success<T>;

  /// 실패 결과 생성.
  const factory Result.failure(AppError error) = Failure<T>;

  /// 성공 여부.
  bool get isSuccess => this is Success<T>;

  /// 실패 여부.
  bool get isFailure => this is Failure<T>;
}

/// 성공 결과.
class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// 실패 결과.
class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppError error;
}
