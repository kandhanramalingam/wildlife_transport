import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readDriverId();
  Future<void> saveAccessToken(String token);
  Future<void> saveDriverId(String driverId);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _driverIdKey = 'driver_id';
  final FlutterSecureStorage _storage;

  const SecureTokenStorage([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  ]);

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readDriverId() => _storage.read(key: _driverIdKey);

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  @override
  Future<void> saveDriverId(String driverId) =>
      _storage.write(key: _driverIdKey, value: driverId);

  @override
  Future<void> clear() => _storage.deleteAll();
}
