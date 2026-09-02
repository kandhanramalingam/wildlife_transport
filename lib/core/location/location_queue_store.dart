import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/delivery/models/location_tracking.dart';

abstract interface class LocationQueueStore {
  Future<List<DriverLocationReading>> load();
  Future<void> replace(List<DriverLocationReading> readings);
}

class SharedPreferencesLocationQueueStore implements LocationQueueStore {
  static const _queueKey = 'pending_driver_locations_v1';
  final SharedPreferencesAsync _preferences;

  SharedPreferencesLocationQueueStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<List<DriverLocationReading>> load() async {
    final value = await _preferences.getString(_queueKey);
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      final readings = <DriverLocationReading>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          readings.add(
            DriverLocationReading.fromStorageJson(
              Map<String, dynamic>.from(item),
            ),
          );
        } catch (_) {
          // Ignore only the malformed queue entry and retain valid readings.
        }
      }
      readings.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      return readings;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> replace(List<DriverLocationReading> readings) async {
    if (readings.isEmpty) {
      await _preferences.remove(_queueKey);
      return;
    }
    await _preferences.setString(
      _queueKey,
      jsonEncode(readings.map((reading) => reading.toStorageJson()).toList()),
    );
  }
}
