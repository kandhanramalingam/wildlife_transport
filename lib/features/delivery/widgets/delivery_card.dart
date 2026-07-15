import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/delivery_model.dart';

class DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final VoidCallback onStart;

  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.onStart,
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
            const SizedBox(height: 12),
            _buildDivider(),
            const SizedBox(height: 12),
            _buildClientInfo(),
            const SizedBox(height: 12),
            _buildStartButton(),
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
        const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
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

  Widget _buildClientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                delivery.clientName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                delivery.clientAddress,
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
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: const Text('Start Delivery'),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[dt.weekday - 1];
    return '$dayName, ${dt.day} ${months[dt.month - 1]}';
  }
}
