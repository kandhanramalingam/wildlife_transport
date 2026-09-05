import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Checks on entry to the home page without starting location tracking.
Future<void> checkHomePermissions(BuildContext context) async {
  try {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    var location = await Geolocator.checkPermission();
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final notifications = android ? await Permission.notification.status : null;
    final locationMissing =
        location != LocationPermission.always &&
        location != LocationPermission.whileInUse;
    final notificationsMissing =
        notifications != null && !notifications.isGranted;
    if (!context.mounted ||
        (servicesEnabled && !locationMissing && !notificationsMissing)) {
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_on_outlined),
        title: const Text('Delivery permissions'),
        content: Text(
          [
            if (!servicesEnabled) 'Turn on location services on your device.',
            if (locationMissing)
              'Allow location access for navigation and active delivery tracking. '
                  'During an active delivery, your location is recorded approximately '
                  'every 30 minutes, including in the background on supported devices. '
                  'Tracking stops when the final delivery is completed or you log out.',
            if (location == LocationPermission.deniedForever)
              kIsWeb
                  ? 'Location is blocked. Allow it in your browser’s site settings.'
                  : 'Location is blocked. Enable it in the app’s device settings.',
            if (notificationsMissing)
              'Allow notifications to show when delivery tracking is running.',
          ].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;

    if (!servicesEnabled && !kIsWeb) {
      await Geolocator.openLocationSettings();
      return;
    }
    if (locationMissing) {
      if (location == LocationPermission.deniedForever) {
        if (!kIsWeb) await Geolocator.openAppSettings();
        return;
      }
      location = await Geolocator.requestPermission();
      if (!context.mounted) return;
      if (location != LocationPermission.always &&
          location != LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location access is still required for delivery tracking.',
            ),
          ),
        );
      }
    }
    if (!context.mounted) return;
    if (notificationsMissing) {
      if (notifications.isPermanentlyDenied) {
        await Geolocator.openAppSettings();
      } else {
        await Permission.notification.request();
      }
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not check permissions. Check location access in settings.',
        ),
      ),
    );
  }
}
