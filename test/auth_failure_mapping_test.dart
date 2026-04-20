// ignore_for_file: avoid_relative_lib_imports

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/modules/auth/data/actions/firebase_auth_action_support.dart';
import '../lib/modules/auth/auth.dart';

void main() {
  group('auth failure mapping', () {
    test(
      'login maps user-not-found to invalidCredentials because the action stays in credential-failure context',
      () {
        final failure = mapLoginFailure(
          FirebaseAuthException(code: 'user-not-found'),
        );

        expect(failure.type, AppFailureType.invalidCredentials);
      },
    );

    test(
      'reset maps user-not-found to notFound because the action stays in account-recovery context',
      () {
        final failure = mapResetFailure(
          FirebaseAuthException(code: 'user-not-found'),
        );

        expect(failure.type, AppFailureType.notFound);
      },
    );

    test(
      'login maps user-disabled to unauthorized without replacing session invalid disabled semantics',
      () {
        final failure = mapLoginFailure(
          FirebaseAuthException(code: 'user-disabled'),
        );

        expect(failure.type, AppFailureType.unauthorized);
      },
    );
  });
}
