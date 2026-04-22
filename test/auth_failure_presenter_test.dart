// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_test/flutter_test.dart';

import '../lib/modules/auth/auth.dart';

void main() {
  group('AuthFailurePresenter', () {
    test('auth flow keeps invalidCredentials as local handling', () {
      final presentation = AuthFailurePresenter.presentForAuthFlow(
        AppFailure.invalidCredentials,
      );

      expect(presentation?.isLocalOnly, isTrue);
      expect(presentation?.shouldReportToRootFeedback, isFalse);
      expect(presentation?.message, '인증 정보가 올바르지 않습니다');
    });

    test('profile action reports network failure to root feedback channel', () {
      final presentation = AuthFailurePresenter.presentForProfileAction(
        AppFailure.network,
      );

      expect(presentation?.isLocalOnly, isFalse);
      expect(presentation?.shouldReportToRootFeedback, isTrue);
      expect(presentation?.message, '네트워크 문제로 요청을 처리할 수 없습니다');
    });
  });
}
