/// deleteAccount action 입력 모델.
///
/// currentPassword는 reauthenticate를 위한 재입력 비밀번호다.
class DeleteAccountInput {
  const DeleteAccountInput({required this.currentPassword});

  final String currentPassword;
}
