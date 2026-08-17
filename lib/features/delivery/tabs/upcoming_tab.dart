import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/error/failure.dart';
import '../../../core/location/current_location.dart';
import '../domain/delivery_repository.dart';
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
  late final DeliveryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = AppDependencies.createDeliveryRepository();
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
            onStartLoading: (lot) => _startLoading(delivery, lot),
            onStartTrip: () => _startTrip(delivery),
          );
        },
      ),
    );
  }

  Future<void> _startLoading(DeliveryModel delivery, DeliveryLot lot) async {
    final loadingOrder = delivery.nextLoadingOrder;
    try {
      if (lot.status != DeliveryStatus.loading) {
        await _repository.startLoading(lot.deliveryId);
        _controller.markLotLoadingStarted(delivery.id, lot.deliveryId);
      }
    } on Failure catch (failure) {
      _showError(failure.message);
      return;
    } catch (_) {
      _showError('Could not start loading. Please try again.');
      return;
    }
    if (!mounted) return;

    final loaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StartDeliveryScreen(
          delivery: DeliveryModel(
            id: lot.deliveryId,
            buyerId: lot.buyerId,
            auctionId: delivery.auctionId,
            dateTime: delivery.dateTime,
            clientName: lot.clientName,
            clientAddress: lot.address,
            paymentStatus: delivery.paymentStatus,
          ),
        ),
      ),
    );
    if (loaded != true || !mounted) return;
    _controller.markLotLoaded(
      delivery.id,
      lot.deliveryId,
      loadingOrder: loadingOrder,
    );
  }

  Future<void> _startTrip(DeliveryModel delivery) async {
    if (delivery.tripStarted) {
      await _openTripCustomers(delivery);
      return;
    }
    if (!delivery.allLotsLoaded) return;
    try {
      final coordinates = await getCurrentCoordinates();
      await _repository.startTrip(
        delivery.id,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      );
    } on CurrentLocationException catch (exception) {
      _showError(exception.message);
      return;
    } on Failure catch (failure) {
      _showError(failure.message);
      return;
    } catch (_) {
      _showError('Could not start the trip. Please try again.');
      return;
    }
    if (!mounted) return;

    _controller.markTripStarted(delivery.id);
    await _openTripCustomers(
      delivery.copyWith(status: DeliveryStatus.inProgress),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openTripCustomers(DeliveryModel delivery) async {
    final updatedLots = await Navigator.of(context).push<List<DeliveryLot>>(
      MaterialPageRoute(
        builder: (_) => TripCustomersScreen(delivery: delivery),
      ),
    );
    if (updatedLots == null || !mounted) return;
    _controller.updateLots(delivery.id, updatedLots);
    if (updatedLots.isNotEmpty &&
        updatedLots.every((lot) => lot.deliveryCompleted)) {
      _controller.markDeliveryCompleted(delivery.id);
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
