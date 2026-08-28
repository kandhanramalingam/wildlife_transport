import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../models/delivery_model.dart';
import '../presentation/today_deliveries_controller.dart';
import '../widgets/delivery_card.dart';

class CompletedTab extends StatefulWidget {
  const CompletedTab({super.key});

  @override
  State<CompletedTab> createState() => CompletedTabState();
}

class CompletedTabState extends State<CompletedTab> {
  late final TodayDeliveriesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppDependencies.createTodayDeliveriesController()
      ..addListener(_onStateChanged)
      ..load();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> refresh() {
    if (_controller.isLoading) return Future.value();
    return _controller.load();
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
    final completedDeliveries = _controller.deliveries
        .where((delivery) => delivery.deliveryCompleted)
        .toList(growable: false);

    if (_controller.isLoading && completedDeliveries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null && completedDeliveries.isEmpty) {
      return _CompletedErrorState(
        message: _controller.errorMessage!,
        buttonLabel: _controller.requiresLogin ? 'Log in again' : 'Retry',
        onRetry: _controller.requiresLogin
            ? AppDependencies.sessionController.logout
            : refresh,
      );
    }

    if (completedDeliveries.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: const _CompletedEmptyState(),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: completedDeliveries.length,
        itemBuilder: (context, index) => DeliveryCard(
          delivery: completedDeliveries[index],
          onStartLoading: _ignoreLotAction,
          onStartTrip: _ignoreAction,
        ),
      ),
    );
  }

  static void _ignoreLotAction(DeliveryLot _) {}

  static void _ignoreAction() {}
}

class _CompletedEmptyState extends StatelessWidget {
  const _CompletedEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.task_alt, size: 64, color: Color(0xFFBDBDBD)),
                SizedBox(height: 16),
                Text(
                  'No completed deliveries today',
                  style: TextStyle(fontSize: 15, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletedErrorState extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onRetry;

  const _CompletedErrorState({
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
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
