import 'package:flutter/material.dart';

Future<void> showLocationTrackingDisclosure(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.location_on_outlined),
      title: const Text('Active Delivery Tracking'),
      content: const Text(
        'AWA Transport records your location approximately every 30 minutes '
        'while this delivery is active, including in the background. Tracking '
        'stops after the final customer delivery is completed or you log out.',
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}
