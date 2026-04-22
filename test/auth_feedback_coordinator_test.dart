// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/modules/auth/auth.dart';
import '../lib/modules/feedback/feedback.dart';

void main() {
  group('AuthFeedbackCoordinator', () {
    test('auth flow invalidCredentials stays local-only', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(authFeedbackCoordinatorProvider)
          .handleAuthFlowFailure(AppFailure.invalidCredentials);

      final state = container.read(feedbackControllerProvider);

      expect(state.activeByChannel, isEmpty);
      expect(state.queue, isEmpty);
    });

    test('profile network failure becomes root error snackbar request', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(authFeedbackCoordinatorProvider)
          .handleProfileActionFailure(AppFailure.network);

      final request = container
          .read(feedbackControllerProvider)
          .activeFor(FeedbackChannel.snackbar);

      expect(request, isNotNull);
      expect(request?.preset, FeedbackPreset.error);
      expect(request?.snackbar?.message, '네트워크 문제로 요청을 처리할 수 없습니다');
    });

    test('reset password success uses root success feedback', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(authFeedbackCoordinatorProvider)
          .handleResetPasswordSuccess();

      final request = container
          .read(feedbackControllerProvider)
          .activeFor(FeedbackChannel.snackbar);

      expect(request?.preset, FeedbackPreset.success);
      expect(request?.snackbar?.message, '비밀번호 재설정 메일을 전송했습니다');
    });
  });
}
