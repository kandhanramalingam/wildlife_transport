import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../models/delivery_model.dart';
import '../presentation/upcoming_deliveries_controller.dart';
import '../screens/start_delivery/start_delivery_screen.dart';
import '../screens/trip_customers_screen.dart';
import '../widgets/delivery_card.dart';

class UpcomingTab extends StatefulWidget {
  const UpcomingTab({super.key});

  @override
  State<UpcomingTab> createState() => _UpcomingTabState();
}

class _UpcomingTabState extends State<UpcomingTab> {
  late final UpcomingDeliveriesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppDependencies.createUpcomingDeliveriesController()
      ..addListener(_onStateChanged)
      ..load();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onStateChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading && _controller.deliveries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null && _controller.deliveries.isEmpty) {
      return _ErrorState(
        message: _controller.errorMessage!,
        buttonLabel: _controller.requiresLogin ? 'Log in again' : 'Retry',
        onRetry: _controller.requiresLogin
            ? AppDependencies.sessionController.logout
            : _controller.load,
      );
    }

    if (_controller.deliveries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.load,
        child: const _EmptyState(message: 'No upcoming deliveries'),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _controller.deliveries.length,
        itemBuilder: (context, index) {
          final delivery = _controller.deliveries[index];
          return DeliveryCard(
            delivery: delivery,
            onStart: () => _onStartDelivery(delivery),
          );
        },
      ),
    );
  }

  Future<void> _onStartDelivery(DeliveryModel delivery) async {
    if (delivery.status == DeliveryStatus.inProgress) {
      await _openTripCustomers(delivery);
      return;
    }

    final tripStarted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StartDeliveryScreen(delivery: delivery),
      ),
    );

    if (tripStarted != true || !mounted) return;
    _controller.markTripStarted(delivery.id);
    await _openTripCustomers(
      delivery.copyWith(status: DeliveryStatus.inProgress),
    );
  }

  Future<void> _openTripCustomers(DeliveryModel delivery) async {
    final completedIds = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => TripCustomersScreen(deliveries: [delivery]),
      ),
    );
    if (completedIds == null || !mounted) return;
    for (final deliveryId in completedIds) {
      _controller.markDeliveryCompleted(deliveryId);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Color(0xFFBDBDBD),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.buttonLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
