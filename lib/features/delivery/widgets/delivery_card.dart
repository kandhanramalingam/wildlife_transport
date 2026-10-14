import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/delivery_model.dart';
import 'client_contact_row.dart';
import 'loading_media_sheet.dart';
import 'trip_document_actions.dart';

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
            if (delivery.isMultiPickup) ...[
              const SizedBox(height: 10),
              _buildPickupStopsSection(),
            ],
            const SizedBox(height: 10),
            _buildDocumentsSection(),
            if (delivery.assignment?.allLotNumbers.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _buildLotsSection(context),
            ],
            if (delivery.hasLoadingMedia) ...[
              const SizedBox(height: 10),
              _buildLoadingMediaSection(context),
            ],
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
          label: delivery.hasPendingOffloading
              ? 'Your status: Awaiting sync'
              : delivery.status == DeliveryStatus.completed &&
                    !delivery.deliveryCompleted
              ? 'Your status: Customers remaining'
              : 'Your status: ${_statusLabel(delivery.status)}',
        ),
        if (delivery.assignments.length > 1)
          ...delivery.assignments
              .where(
                (a) =>
                    a.vehicleId != delivery.assignedVehicleId &&
                    a.lotNumbers.isNotEmpty,
              )
              .map(
                (a) => _AssignmentChip(
                  icon: Icons.local_shipping_outlined,
                  label: '${a.vehicleLabel} Lots: ${a.lotNumbers.join(', ')}',
                ),
              ),
        if (delivery.isMultiPickup)
          const _AssignmentChip(
            icon: Icons.alt_route,
            label: 'Multi Pickup Point',
          ),
      ],
    );
  }

  Widget _buildLotsSection(BuildContext context) {
    final lotNumbers = delivery.assignment!.allLotNumbers;
    final detailsByNumber = {
      for (final lot in delivery.lotDetails) lot.lotNumber: lot,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lots Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final lotNumber in lotNumbers)
                ActionChip(
                  avatar: const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  label: Text('Lot $lotNumber'),
                  tooltip: 'View Lot $lotNumber details',
                  onPressed: () => _showLotDetails(
                    context,
                    lotNumber,
                    detailsByNumber[lotNumber],
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color:
                        detailsByNumber[lotNumber]?.comment.trim().isNotEmpty ==
                            true
                        ? Colors.red
                        : AppTheme.primary.withValues(alpha: 0.35),
                  ),
                  labelStyle: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showLotDetails(
    BuildContext context,
    String lotNumber,
    DeliveryLotDetails? details,
  ) {
    final comment = details?.comment.trim() ?? '';
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lot $lotNumber',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: comment.isEmpty
                      ? AppTheme.primary.withValues(alpha: 0.06)
                      : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                  border: comment.isEmpty
                      ? null
                      : Border.all(color: const Color(0xFFD99000), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (comment.isNotEmpty) ...[
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFF8A4B00),
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            comment.isEmpty
                                ? 'Comment'
                                : 'Important lot comment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: comment.isEmpty
                                  ? AppTheme.textSecondary
                                  : const Color(0xFF8A4B00),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      comment.isEmpty
                          ? 'No comment added for this lot.'
                          : comment,
                      style: TextStyle(
                        fontSize: comment.isEmpty ? 14 : 16,
                        fontWeight: comment.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w700,
                        height: 1.4,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (details?.description.trim().isNotEmpty == true) ...[
                const SizedBox(height: 14),
                _buildDetailRow(
                  Icons.pets_outlined,
                  details!.description.trim(),
                ),
              ],
              if (details?.quantity != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.numbers_outlined,
                  'Quantity: ${details!.quantity}',
                ),
              ],
              if (details?.status.trim().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  Icons.check_circle_outline,
                  'Status: ${details!.status.trim()}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickupStopsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route, size: 16, color: AppTheme.primary),
              SizedBox(width: 6),
              Text(
                'Pickup Stops (Multi-Pickup Trip)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (delivery.pickupNotice != null &&
              delivery.pickupNotice!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              delivery.pickupNotice!.trim(),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
          ],
          if (delivery.pickupStops.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...delivery.pickupStops.map(
              (stop) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stop ${stop.order}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stop.address.isNotEmpty)
                            Text(
                              stop.address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (stop.lotNumbers.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Lots to collect: ${stop.lotNumbers.join(', ')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TripDocumentActions(
        invoicePath: delivery.invoicePath,
        permits: delivery.permits,
        maps: delivery.maps,
      ),
    );
  }

  Widget _buildLoadingMediaSection(BuildContext context) {
    final photoCount = delivery.allLoadingPhotos.length;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => LoadingMediaSheet.show(context, delivery),
        icon: const Icon(Icons.photo_library_outlined, size: 17),
        label: Text(
          'View Loading Photos ($photoCount)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
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
          ClientContactRow(
            contactNumber: lot.contactNumber,
            clientName: lot.clientName,
            destinationLatitude: lot.latitude,
            destinationLongitude: lot.longitude,
          ),
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
