import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_permissions.dart';

Future<bool> requestActiveDeliveryTrackingAccess(
  BuildContext context, {
  bool showDisclosure = true,
}) async {
  if (showDisclosure) {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_on_outlined),
        title: const Text('Active Delivery Tracking'),
        content: const Text(
          'AWA Transport records your location approximately every 30 minutes '
          'while this delivery is active, including in the background. Tracking '
          'stops after the final customer delivery is completed or you log out. '
          'On Android, an ongoing notification is shown while tracking runs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return false;
  }

  final locationAllowed = await requestLocationAccess(
    context,
    LocationPermissionPurpose.activeTracking,
  );
  if (!locationAllowed || !context.mounted) return false;

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final status = await Permission.notification.status;
    if (status.isDenied) await Permission.notification.request();
  } else if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    // Apple requires a separate escalation after When In Use is granted.
    if (!await Permission.locationAlways.isGranted) {
      await Permission.locationAlways.request();
    }
  }
  return true;
}
