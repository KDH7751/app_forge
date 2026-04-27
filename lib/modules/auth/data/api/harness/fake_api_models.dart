/// In-memory API harness account row.
class FakeApiAuthAccount {
  FakeApiAuthAccount({
    required this.uid,
    required this.email,
    required this.password,
    this.authProviderDeleted = false,
    this.userDocumentDeleted = false,
    this.blocked = false,
    this.disabled = false,
  });

  final String uid;
  final String email;
  String password;
  bool authProviderDeleted;
  bool userDocumentDeleted;
  bool blocked;
  bool disabled;
}
