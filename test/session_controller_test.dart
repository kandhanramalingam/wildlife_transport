import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/core/storage/token_storage.dart';
import 'package:wildlife_transport/features/auth/presentation/session_controller.dart';

void main() {
  test('restores a session when the stored JWT is not expired', () async {
    final storage = _MemoryTokenStorage(
      _jwt(DateTime.now().add(const Duration(hours: 1))),
      'driver-1',
    );
    final controller = SessionController(storage);

    await controller.initialize();

    expect(controller.status, SessionStatus.authenticated);
    expect(storage.token, isNotNull);
    expect(controller.driverId, 'driver-1');
    controller.dispose();
  });

  test('clears an expired stored JWT', () async {
    final storage = _MemoryTokenStorage(
      _jwt(DateTime.now().subtract(const Duration(minutes: 1))),
    );
    final controller = SessionController(storage);

    await controller.initialize();

    expect(controller.status, SessionStatus.unauthenticated);
    expect(storage.token, isNull);
    controller.dispose();
  });
}

String _jwt(DateTime expiration) {
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256'})));
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'exp': expiration.millisecondsSinceEpoch ~/ 1000})),
  );
  return '$header.$payload.signature';
}

class _MemoryTokenStorage implements TokenStorage {
  String? token;
  String? driverId;

  _MemoryTokenStorage(this.token, [this.driverId]);

  @override
  Future<void> clear() async {
    token = null;
    driverId = null;
  }

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<String?> readDriverId() async => driverId;

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<void> saveDriverId(String driverId) async => this.driverId = driverId;
}
