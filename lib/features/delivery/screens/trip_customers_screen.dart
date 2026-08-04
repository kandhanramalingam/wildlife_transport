import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/delivery_model.dart';
import 'customer_details_screen.dart';

class TripCustomersScreen extends StatefulWidget {
  final List<DeliveryModel> deliveries;

  const TripCustomersScreen({super.key, required this.deliveries});

  @override
  State<TripCustomersScreen> createState() => _TripCustomersScreenState();
}

class _TripCustomersScreenState extends State<TripCustomersScreen> {
  final Set<String> _completedDeliveryIds = {};

  Future<void> _openCustomerDetails(DeliveryModel delivery) async {
    final completedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CustomerDetailsScreen(
          delivery: delivery,
          tripEnded: _completedDeliveryIds.contains(delivery.id),
        ),
      ),
    );
    if (completedId == null || !mounted) return;
    setState(() => _completedDeliveryIds.add(completedId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip ended successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _close() {
    Navigator.of(context).pop(_completedDeliveryIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer Delivery'),
          leading: BackButton(onPressed: _close),
        ),
        body: widget.deliveries.isEmpty
            ? const Center(child: Text('No customer delivery found'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: widget.deliveries.length,
                itemBuilder: (context, index) {
                  final delivery = widget.deliveries[index];
                  return _CustomerCard(
                    delivery: delivery,
                    completed: _completedDeliveryIds.contains(delivery.id),
                    onTap: () => _openCustomerDetails(delivery),
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
  final VoidCallback onTap;

  const _CustomerCard({
    required this.delivery,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
              if (completed)
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Trip Ended',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
              fontSize: emphasized ? 18 : 15,
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
