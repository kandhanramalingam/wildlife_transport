import 'package:flutter/material.dart';
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
          color: tracker.warningMessage == null
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.orange.shade100,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    tracker.warningMessage == null
                        ? Icons.location_on
                        : Icons.location_disabled_outlined,
                    size: 18,
                    color: tracker.warningMessage == null
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
                        color: tracker.warningMessage == null
                            ? AppTheme.primary
                            : Colors.orange.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (tracker.warningMessage != null)
                    if (permissionWarning)
                      IconButton(
                        onPressed: Geolocator.openAppSettings,
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

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
