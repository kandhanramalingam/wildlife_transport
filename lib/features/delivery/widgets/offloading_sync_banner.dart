import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../offline/offloading_queue_store.dart';

class OffloadingSyncBanner extends StatelessWidget {
  const OffloadingSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AppDependencies.offloadingSyncService;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (service.pendingCount == 0 && service.lastError == null) {
          return const SizedBox.shrink();
        }
        final count = service.pendingCount;
        return Material(
          color: const Color(0xFFFFF3CD),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      service.lastError ??
                          '$count off-loading action${count == 1 ? '' : 's'} awaiting sync to portal',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (service.lastFailedJob != null)
                    TextButton(
                      onPressed: () =>
                          _showSavedSubmission(context, service.lastFailedJob!),
                      child: const Text('Details'),
                    ),
                  TextButton(
                    onPressed: service.isSyncing ? null : service.flushPending,
                    child: Text(service.isSyncing ? 'Syncing…' : 'Retry now'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSavedSubmission(
    BuildContext context,
    PendingOffloadingJob job,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Saved off-loading needs attention'),
      content: SelectableText(
        'The server has not accepted this submission. Its evidence remains '
        'saved on this device. Share these details to locate the delivery '
        'in the portal.\n\n'
        'Delivery ID: ${job.deliveryId}\n'
        'Buyer ID: ${job.submission.buyerId}\n'
        'Vehicle ID: ${job.vehicleId ?? "Unavailable"}\n'
        'Saved: ${job.queuedAt.toLocal()}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
