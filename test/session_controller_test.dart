import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/core/storage/token_storage.dart';
import 'package:wildlife_transport/features/auth/presentation/session_controller.dart';

void main() {
  test(
    'restores self-load visibility after restart and resets it on logout',
    () async {
      final storage = _MemoryTokenStorage(
        _jwt(DateTime.now().add(const Duration(hours: 1))),
        'driver-1',
      )..isSelfLoad = true;
      final controller = SessionController(storage);
      await controller.initialize();
      expect(controller.isSelfLoad, isTrue);
      await controller.logout();
      expect(controller.isSelfLoad, isFalse);
      expect(storage.isSelfLoad, isFalse);
      controller.dispose();
    },
  );

  test(
    'reads the login role when marking a new session authenticated',
    () async {
      final storage = _MemoryTokenStorage(
        _jwt(DateTime.now().add(const Duration(hours: 1))),
        'driver-1',
      )..isSelfLoad = true;
      final controller = SessionController(storage);
      await controller.markAuthenticated(driverId: 'driver-1');
      expect(controller.isSelfLoad, isTrue);
      controller.dispose();
    },
  );

  test(
    'manual logout preserves authentication while a delivery is active',
    () async {
      final storage = _MemoryTokenStorage(
        _jwt(DateTime.now().add(const Duration(hours: 1))),
        'driver-1',
      );
      var blocked = true;
      final controller = SessionController(
        storage,
        logoutBlockReason: () async =>
            blocked ? 'Finish your active delivery before logging out.' : null,
      );
      await controller.initialize();
      expect(await controller.requestLogout(), contains('active delivery'));
      expect(controller.status, SessionStatus.authenticated);
      expect(storage.token, isNotNull);
      blocked = false;
      expect(await controller.requestLogout(), isNull);
      expect(controller.status, SessionStatus.unauthenticated);
      expect(storage.token, isNull);
      controller.dispose();
    },
  );

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
  bool isSelfLoad = false;

  _MemoryTokenStorage(this.token, [this.driverId]);

  @override
  Future<void> clear() async {
    token = null;
    driverId = null;
    isSelfLoad = false;
  }

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<String?> readDriverId() async => driverId;

  @override
  Future<bool> readIsSelfLoad() async => isSelfLoad;

  @override
  Future<void> saveIsSelfLoad(bool value) async => isSelfLoad = value;

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<void> saveDriverId(String driverId) async => this.driverId = driverId;
}
