/// auth_entry page 간 단발성 UI notice 전달 모델.
class AuthEntryNotice {
  const AuthEntryNotice.resetPasswordSuccess()
    : kind = AuthEntryNoticeKind.resetPasswordSuccess;

  final AuthEntryNoticeKind kind;
}

/// auth_entry notice 종류.
enum AuthEntryNoticeKind { resetPasswordSuccess }
