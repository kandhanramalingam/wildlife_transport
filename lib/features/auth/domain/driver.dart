class Driver {
  final String id;
  final String name;
  final String phone;

  const Driver({required this.id, required this.name, required this.phone});
}

class LoginResult {
  final Driver driver;

  const LoginResult({required this.driver});
}
