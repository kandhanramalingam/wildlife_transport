import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/delivery_model.dart';
import 'client_contact_row.dart';

typedef LotReorderCallback = void Function(int oldIndex, int newIndex);

class DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final ValueChanged<DeliveryLot> onStartLoading;
  final VoidCallback onStartTrip;
  final LotReorderCallback? onReorderLot;

  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.onStartLoading,
    required this.onStartTrip,
    this.onReorderLot,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateTimeRow(),
            const SizedBox(height: 10),
            _buildAssignmentSummary(),
            const SizedBox(height: 12),
            _buildDivider(),
            const SizedBox(height: 12),
            ...delivery.lots.asMap().entries.expand((entry) sync* {
              if (entry.key > 0) {
                yield const Divider(height: 25, color: Color(0xFFEEEEEE));
              }
              yield _buildLot(entry.key, entry.value);
            }),
            const SizedBox(height: 16),
            _buildTripButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow() {
    final timeStr = _formatTime(delivery.dateTime);
    final dateStr = _formatDate(delivery.dateTime);

    return Row(
      children: [
        const Icon(Icons.access_time, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          timeStr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(
          Icons.calendar_today,
          size: 14,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          dateStr,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }

  Widget _buildAssignmentSummary() {
    final driverName = delivery.assignment?.driverName.trim() ?? '';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (delivery.assignment != null)
          _AssignmentChip(
            icon: Icons.person_outline,
            label: driverName.isEmpty
                ? 'Driver name unavailable'
                : 'Assigned driver: $driverName',
          ),
        _AssignmentChip(
          icon: Icons.person_pin_circle_outlined,
          label: 'Your status: ${_statusLabel(delivery.status)}',
        ),
      ],
    );
  }

  String _statusLabel(DeliveryStatus status) => switch (status) {
    DeliveryStatus.pending => 'Pending',
    DeliveryStatus.loading => 'Loading',
    DeliveryStatus.loadingCompleted => 'Loading completed',
    DeliveryStatus.inProgress => 'In delivery',
    DeliveryStatus.atDeliveryPoint => 'At delivery location',
    DeliveryStatus.offloading => 'Offloading',
    DeliveryStatus.completed => 'Completed',
  };

  Widget _buildLot(int index, DeliveryLot lot) {
    final loaded = lot.loadingCompleted;
    final loadingStarted = lot.status == DeliveryStatus.loading;
    final deliveryCompleted =
        delivery.deliveryCompleted || lot.deliveryCompleted;
    final activeLoadingIndex = delivery.lots.indexWhere(
      (item) => item.status == DeliveryStatus.loading,
    );
    final nextPendingIndex = delivery.lots.indexWhere(
      (item) => !item.loadingCompleted,
    );
    final nextLoadingIndex = activeLoadingIndex == -1
        ? nextPendingIndex
        : activeLoadingIndex;
    final waitingForTurn =
        !loaded && !deliveryCompleted && index != nextLoadingIndex;
    final canReorder =
        onReorderLot != null &&
        delivery.lots.length > 1 &&
        delivery.lots.every((item) => item.status == DeliveryStatus.pending);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.person_outline,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lot.clientName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (onReorderLot != null && delivery.lots.length > 1) ...[
              _LoadingOrderBadge(order: index + 1),
              IconButton(
                onPressed: canReorder && index > 0
                    ? () => onReorderLot!(index, index - 1)
                    : null,
                icon: const Icon(Icons.keyboard_arrow_up),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: EdgeInsets.zero,
                tooltip: 'Move earlier',
              ),
              IconButton(
                onPressed: canReorder && index < delivery.lots.length - 1
                    ? () => onReorderLot!(index, index + 1)
                    : null,
                icon: const Icon(Icons.keyboard_arrow_down),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: EdgeInsets.zero,
                tooltip: 'Move later',
              ),
            ],
          ],
        ),
        if (lot.address.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lot.address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (lot.farmName.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDetailRow(Icons.agriculture_outlined, 'Farm: ${lot.farmName}'),
        ],
        if (lot.companyName.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.business_outlined,
            'Company: ${lot.companyName}',
          ),
        ],
        if (lot.contactNumber.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClientContactRow(contactNumber: lot.contactNumber),
        ],
        if (lot.latitude.isNotEmpty || lot.longitude.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.my_location_outlined,
            [
              if (lot.latitude.isNotEmpty) 'Lat: ${lot.latitude}',
              if (lot.longitude.isNotEmpty) 'Long: ${lot.longitude}',
            ].join('  •  '),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: loaded || deliveryCompleted || waitingForTurn
                ? null
                : () => onStartLoading(lot),
            icon: Icon(
              loaded || deliveryCompleted
                  ? Icons.check_circle_outline
                  : Icons.inventory_2_outlined,
            ),
            label: Text(
              deliveryCompleted
                  ? 'Delivery Completed'
                  : loaded
                  ? 'Loading Completed'
                  : waitingForTurn
                  ? 'Waiting for Loading Turn'
                  : loadingStarted
                  ? 'Continue Loading'
                  : 'Start Loading',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripButton() {
    final tripStarted = delivery.tripStarted;
    final completed = delivery.deliveryCompleted;
    final canStartTrip = delivery.allLotsLoaded;
    final showDeliveryProgress = tripStarted || completed;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: completed || (!tripStarted && !canStartTrip)
            ? null
            : onStartTrip,
        icon: Icon(
          showDeliveryProgress ? Icons.task_alt : Icons.play_arrow_rounded,
          size: 20,
        ),
        label: Text(
          showDeliveryProgress ? delivery.deliveryProgressLabel : 'Start Trip',
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[dt.weekday - 1];
    return '$dayName, ${dt.day} ${months[dt.month - 1]}';
  }
}

class _LoadingOrderBadge extends StatelessWidget {
  final int order;

  const _LoadingOrderBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Load $order',
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AssignmentChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AssignmentChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
