import 'package:flutter/material.dart';
import '../models/delivery_model.dart';
import '../screens/start_delivery/start_delivery_screen.dart';
import '../widgets/delivery_card.dart';

class UpcomingTab extends StatelessWidget {
  const UpcomingTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (upcomingDeliveries.isEmpty) {
      return const _EmptyState(message: 'No upcoming deliveries');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: upcomingDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = upcomingDeliveries[index];
        return DeliveryCard(
          delivery: delivery,
          onStart: () => _onStartDelivery(context, delivery),
        );
      },
    );
  }

  void _onStartDelivery(BuildContext context, DeliveryModel delivery) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StartDeliveryScreen(delivery: delivery),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 15, color: Color(0xFF757575)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
