import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/delivery_model.dart';
import 'start_delivery/start_delivery_screen.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final DeliveryCustomer customer;
  final DeliveryModel parentDelivery;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
    required this.parentDelivery,
  });

  DeliveryModel get _delivery => DeliveryModel(
    id: customer.deliveryId,
    buyerId: customer.buyerId,
    auctionId: parentDelivery.auctionId,
    dateTime: parentDelivery.dateTime,
    clientName: customer.clientName,
    clientAddress: parentDelivery.clientAddress,
    status: customer.completed
        ? DeliveryStatus.completed
        : DeliveryStatus.inProgress,
    paymentStatus: parentDelivery.paymentStatus,
  );

  Future<void> _arrivedAtLocation(BuildContext context) async {
    final ended = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StartDeliveryScreen(
          delivery: _delivery,
          workflow: DeliveryWorkflow.arrival,
        ),
      ),
    );
    if (ended == true && context.mounted) {
      Navigator.of(context).pop(customer.deliveryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.person_outline,
                          value: customer.clientName,
                          emphasized: true,
                        ),
                        const Divider(height: 32),
                        _DetailRow(
                          icon: Icons.location_on_outlined,
                          value: parentDelivery.clientAddress,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: customer.completed
                      ? null
                      : () => _arrivedAtLocation(context),
                  icon: Icon(
                    customer.completed
                        ? Icons.check_circle_outline
                        : Icons.location_on_outlined,
                  ),
                  label: Text(
                    customer.completed ? 'Trip Ended' : 'Arrived at Location',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool emphasized;

  const _DetailRow({
    required this.icon,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 20 : 17,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
              color: emphasized ? AppTheme.textPrimary : AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
