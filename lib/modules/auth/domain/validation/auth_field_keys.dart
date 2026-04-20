/// auth validation이 사용하는 공식 field key 집합.
final class AuthFailureField {
  const AuthFailureField._();

  static const String email = 'email';
  static const String password = 'password';
  static const String confirmPassword = 'confirmPassword';
  static const String currentPassword = 'currentPassword';
  static const String newPassword = 'newPassword';
  static const String confirmNewPassword = 'confirmNewPassword';
}
