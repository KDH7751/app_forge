/// project auth flow route 간 단발성 UX notice 전달 모델.
class AuthFlowNotice {
  const AuthFlowNotice.resetPasswordSuccess()
    : kind = AuthFlowNoticeKind.resetPasswordSuccess;

  final AuthFlowNoticeKind kind;
}

/// auth_flow consumer route에서 사용하는 notice 종류.
enum AuthFlowNoticeKind { resetPasswordSuccess }
