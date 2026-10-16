class LoginResponseDto {
  final String accessToken;
  final DriverDto driver;

  const LoginResponseDto({required this.accessToken, required this.driver});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: json['access_token'] as String,
      driver: DriverDto.fromJson(json['driver'] as Map<String, dynamic>),
    );
  }
}

class DriverDto {
  final String id;
  final String name;
  final String phone;
  final bool isSelfLoad;

  const DriverDto({
    required this.id,
    required this.name,
    required this.phone,
    this.isSelfLoad = false,
  });

  factory DriverDto.fromJson(Map<String, dynamic> json) {
    return DriverDto(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      isSelfLoad: json['isSelfLoad'] == true,
    );
  }
}
