/// changePassword action 입력 모델.
class ChangePasswordInput {
  const ChangePasswordInput({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;
}
