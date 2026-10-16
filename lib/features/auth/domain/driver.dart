class Driver {
  final String id;
  final String name;
  final String phone;
  final bool isSelfLoad;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.isSelfLoad = false,
  });
}

class LoginResult {
  final Driver driver;

  const LoginResult({required this.driver});
}
