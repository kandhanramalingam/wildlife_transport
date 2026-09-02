import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/storage/token_storage.dart';

enum SessionStatus { checking, authenticated, unauthenticated }

class SessionController extends ChangeNotifier {
  final TokenStorage _tokenStorage;
  Timer? _expiryTimer;

  SessionStatus status = SessionStatus.checking;
  String? driverId;

  SessionController(this._tokenStorage);

  Future<void> initialize() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty || _expirationOf(token) == null) {
      await _setUnauthenticated(clearToken: token != null);
      return;
    }

    final expiration = _expirationOf(token)!;
    if (!expiration.isAfter(DateTime.now())) {
      await _setUnauthenticated(clearToken: true);
      return;
    }

    driverId = await _tokenStorage.readDriverId() ?? _driverIdOf(token);
    _setAuthenticatedUntil(expiration);
  }

  Future<void> markAuthenticated({String? driverId}) async {
    final token = await _tokenStorage.readAccessToken();
    final expiration = token == null ? null : _expirationOf(token);
    if (expiration == null || !expiration.isAfter(DateTime.now())) {
      await _setUnauthenticated(clearToken: true);
      return;
    }
    this.driverId =
        driverId ?? await _tokenStorage.readDriverId() ?? _driverIdOf(token!);
    _setAuthenticatedUntil(expiration);
  }

  Future<void> logout() => _setUnauthenticated(clearToken: true);

  void _setAuthenticatedUntil(DateTime expiration) {
    _expiryTimer?.cancel();
    status = SessionStatus.authenticated;
    _expiryTimer = Timer(expiration.difference(DateTime.now()), logout);
    notifyListeners();
  }

  Future<void> _setUnauthenticated({required bool clearToken}) async {
    _expiryTimer?.cancel();
    if (clearToken) await _tokenStorage.clear();
    driverId = null;
    status = SessionStatus.unauthenticated;
    notifyListeners();
  }

  DateTime? _expirationOf(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return null;
      final exp = payload['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      ).toLocal();
    } catch (_) {
      return null;
    }
  }

  String? _driverIdOf(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return null;
      for (final key in ['driverId', 'driver_id', 'sub', 'id']) {
        final value = payload[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
