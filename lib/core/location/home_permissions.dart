import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

bool _permissionCheckInProgress = false;

enum LocationPermissionPurpose {
  delivery,
  navigation,
  customerLocation,
  deliveryEvidence,
  activeTracking,
}

extension on LocationPermissionPurpose {
  String get explanation => switch (this) {
    LocationPermissionPurpose.delivery =>
      'AWA Transport uses your location for delivery navigation, evidence, and active-trip tracking.',
    LocationPermissionPurpose.navigation =>
      'Allow location access to calculate a route from your current position and provide live navigation.',
    LocationPermissionPurpose.customerLocation =>
      'Allow location access to save and confirm the customer delivery point.',
    LocationPermissionPurpose.deliveryEvidence =>
      'Allow location access to attach the capture position to delivery photos and videos.',
    LocationPermissionPurpose.activeTracking =>
      'Allow location access so AWA Transport can record the driver position during an active delivery.',
  };
}

/// Backward-compatible wrapper for callers that need general delivery access.
Future<void> checkHomePermissions(BuildContext context) async {
  await requestLocationAccess(context, LocationPermissionPurpose.delivery);
}

/// Requests foreground location from a visible, user-initiated screen.
///
/// Android supplies the correct system dialog for the installed OS version,
/// including approximate/precise and one-time choices where supported.
Future<bool> requestLocationAccess(
  BuildContext context,
  LocationPermissionPurpose purpose,
) async {
  if (_permissionCheckInProgress) return false;
  _permissionCheckInProgress = true;
  try {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    var location = await Geolocator.checkPermission();
    final locationMissing =
        location != LocationPermission.always &&
        location != LocationPermission.whileInUse;
    if (!context.mounted) return false;
    if (servicesEnabled && !locationMissing) return true;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_on_outlined),
        title: const Text('Delivery permissions'),
        content: Text(
          [
            if (!servicesEnabled) 'Turn on location services on your device.',
            if (locationMissing) purpose.explanation,
            if (location == LocationPermission.deniedForever)
              kIsWeb
                  ? 'Location is blocked. Allow it in your browser’s site settings.'
                  : 'Location is blocked. Enable it in the app’s device settings.',
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
    if (proceed != true || !context.mounted) return false;

    if (!servicesEnabled) {
      if (!kIsWeb) await Geolocator.openLocationSettings();
      return false;
    }
    if (locationMissing) {
      if (location == LocationPermission.deniedForever) {
        if (!kIsWeb) await Geolocator.openAppSettings();
        return false;
      }
      location = await Geolocator.requestPermission();
      if (!context.mounted) return false;
      // Read the platform status again after Android closes its permission
      // sheet. This avoids acting on a stale result on some devices.
      location = await Geolocator.checkPermission();
      if (!context.mounted) return false;
      if (location != LocationPermission.always &&
          location != LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location access is still required for delivery tracking.',
            ),
          ),
        );
        return false;
      }
    }
    return true;
  } catch (_) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not check permissions. Check location access in settings.',
        ),
      ),
    );
    return false;
  } finally {
    _permissionCheckInProgress = false;
  }
}
