import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'trip_location_tracker.dart';
import 'package:geolocator/geolocator.dart';

import '../di/app_dependencies.dart';
import '../theme/app_theme.dart';

class TrackingStatusBanner extends StatelessWidget {
  const TrackingStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = AppDependencies.tripLocationTracker;
    return ListenableBuilder(
      listenable: tracker,
      builder: (context, _) {
        if (!tracker.isActive) return const SizedBox.shrink();
        final browserNotice =
            kIsWeb &&
            tracker.warningMessage == TripLocationTracker.webTrackingNotice;
        final hasError = tracker.warningMessage != null && !browserNotice;
        final uploadedAt = tracker.lastUploadedAt?.toLocal();
        final permissionWarning =
            tracker.warningMessage?.toLowerCase().contains('permission') ==
                true ||
            tracker.warningMessage?.toLowerCase().contains('device settings') ==
                true ||
            tracker.warningMessage?.toLowerCase().contains('allow all') == true;
        final details = <String>[
          if (uploadedAt != null) 'Last sent ${_time(uploadedAt)}',
          if (tracker.pendingCount > 0)
            '${tracker.pendingCount} update${tracker.pendingCount == 1 ? '' : 's'} pending',
        ];
        return Material(
          color: !hasError
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.orange.shade100,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    !hasError
                        ? Icons.location_on
                        : Icons.location_disabled_outlined,
                    size: 18,
                    color: !hasError
                        ? AppTheme.primary
                        : Colors.orange.shade900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tracker.warningMessage ??
                          (details.isEmpty
                              ? 'Active delivery tracking is on'
                              : 'Tracking on • ${details.join(' • ')}'),
                      style: TextStyle(
                        color: !hasError
                            ? AppTheme.primary
                            : Colors.orange.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasError)
                    if (permissionWarning && kIsWeb)
                      TextButton(
                        onPressed: () => _showBrowserHelp(context),
                        child: const Text('Location help'),
                      )
                    else if (permissionWarning)
                      IconButton(
                        onPressed: () => _openDeviceSettings(context),
                        tooltip: 'Open location settings',
                        icon: const Icon(Icons.settings_outlined),
                      )
                    else
                      TextButton(
                        onPressed: () =>
                            tracker.start(tracker.activeDeliveryId!),
                        child: const Text('Retry'),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBrowserHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow browser location'),
        content: const Text(
          'Open the site controls beside the browser address, '
          'set Location to Allow, then reload this page. Also enable location '
          'access for your browser in device settings. Keep this tab open during delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeviceSettings(BuildContext context) async {
    try {
      if (await Geolocator.openAppSettings()) return;
    } catch (_) {
      // Some platforms cannot open app settings programmatically.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open your device settings and allow location access for AWA Transport.',
          ),
        ),
      );
    }
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
