// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Auth Action Controller
///
/// 역할:
/// - auth presentation layer의 controller로 login/logout 액션 상태와 AppError 표시 상태를 소유함.
///
/// 경계:
/// - auth는 UI page를 소유하지 않음.
/// - navigation은 직접 호출하지 않음.
/// - Firebase/Firestore 접근은 repository에 위임함.
/// ===================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_error.dart';
import '../domain/auth_session.dart';
import '../domain/result.dart';
import 'auth_repository_provider.dart';

/// auth action 상태 모델.
class AuthActionState {
  const AuthActionState({this.isLoading = false, this.error});

  final bool isLoading;
  final AppError? error;

  /// 일부 상태만 바꾼 복사본.
  AuthActionState copyWith({
    bool? isLoading,
    AppError? error,
    bool clearError = false,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// auth action controller provider.
final authActionControllerProvider =
    NotifierProvider<AuthActionController, AuthActionState>(
      AuthActionController.new,
    );

/// auth 액션 실행 controller.
class AuthActionController extends Notifier<AuthActionState> {
  @override
  AuthActionState build() {
    return const AuthActionState();
  }

  /// login 액션 실행.
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);

    if (result is Success<AuthSession>) {
      state = state.copyWith(isLoading: false, clearError: true);

      return const Result<void>.success(null);
    }

    final failure = result as Failure<AuthSession>;
    state = state.copyWith(isLoading: false, error: failure.error);

    return Result<void>.failure(failure.error);
  }

  /// logout 액션 실행.
  Future<Result<void>> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref.read(authRepositoryProvider).logout();

    if (result is Success<void>) {
      state = state.copyWith(isLoading: false, clearError: true);

      return result;
    }

    final failure = result as Failure<void>;
    state = state.copyWith(isLoading: false, error: failure.error);

    return result;
  }
}
