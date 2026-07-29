import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/delivery_model.dart';
import 'start_delivery/start_delivery_screen.dart';

class TripCustomersScreen extends StatefulWidget {
  final List<DeliveryModel> deliveries;

  const TripCustomersScreen({super.key, required this.deliveries});

  @override
  State<TripCustomersScreen> createState() => _TripCustomersScreenState();
}

class _TripCustomersScreenState extends State<TripCustomersScreen> {
  final Set<String> _completedDeliveryIds = {};

  Future<void> _arrivedAtLocation(DeliveryModel delivery) async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StartDeliveryScreen(
          delivery: delivery,
          workflow: DeliveryWorkflow.arrival,
        ),
      ),
    );

    if (completed != true || !mounted) return;
    setState(() => _completedDeliveryIds.add(delivery.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arrival details captured successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_completedDeliveryIds.toList());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer Deliveries'),
          leading: BackButton(
            onPressed: () =>
                Navigator.of(context).pop(_completedDeliveryIds.toList()),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: widget.deliveries.length,
          itemBuilder: (context, index) {
            final delivery = widget.deliveries[index];
            final completed = _completedDeliveryIds.contains(delivery.id);
            return _CustomerCard(
              delivery: delivery,
              completed: completed,
              onArrived: () => _arrivedAtLocation(delivery),
            );
          },
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final DeliveryModel delivery;
  final bool completed;
  final VoidCallback onArrived;

  const _CustomerCard({
    required this.delivery,
    required this.completed,
    required this.onArrived,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              icon: Icons.person_outline,
              text: delivery.clientName,
              emphasized: true,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.location_on_outlined,
              text: delivery.clientAddress,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              text: _formatDate(delivery.dateTime),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: completed ? null : onArrived,
                icon: Icon(
                  completed
                      ? Icons.check_circle_outline
                      : Icons.location_on_outlined,
                ),
                label: Text(
                  completed ? 'Arrival Captured' : 'Arrived at Location',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
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
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool emphasized;

  const _DetailRow({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Icon(icon, size: 20, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: emphasized ? 16 : 14,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
              color: emphasized ? AppTheme.textPrimary : AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
