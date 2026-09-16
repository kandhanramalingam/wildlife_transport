import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/error/failure.dart';
import '../../../core/location/location_tracking_disclosure.dart';
import '../domain/delivery_repository.dart';
import '../models/delivery_model.dart';
import '../presentation/today_deliveries_controller.dart';
import '../screens/start_delivery/start_delivery_screen.dart';
import '../screens/trip_customers_screen.dart';
import '../widgets/delivery_card.dart';

class TodayTab extends StatefulWidget {
  const TodayTab({super.key});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  late final TodayDeliveriesController _controller;
  late final DeliveryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = AppDependencies.createDeliveryRepository();
    _controller = AppDependencies.createTodayDeliveriesController()
      ..addListener(_onStateChanged)
      ..load();
  }

  void _onStateChanged() {
    if (!_controller.isLoading && _controller.errorMessage == null) {
      final activeTrips = _controller.deliveries.where(
        (delivery) => delivery.tripStarted && !delivery.deliveryCompleted,
      );
      if (activeTrips.isEmpty) {
        unawaited(AppDependencies.tripLocationTracker.stop());
      } else {
        unawaited(
          AppDependencies.tripLocationTracker.start(activeTrips.first.id),
        );
      }
    }
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
    final activeDeliveries = _controller.deliveries
        .where((delivery) => !delivery.deliveryCompleted)
        .toList(growable: false);

    if (_controller.isLoading && activeDeliveries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null && activeDeliveries.isEmpty) {
      return _ErrorState(
        message: _controller.errorMessage!,
        buttonLabel: _controller.requiresLogin ? 'Log in again' : 'Retry',
        onRetry: _controller.requiresLogin ? _goToLogin : _controller.load,
      );
    }

    if (activeDeliveries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.load,
        child: const _EmptyState(message: 'No deliveries scheduled for today'),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: activeDeliveries.length,
        itemBuilder: (context, index) {
          final delivery = activeDeliveries[index];
          return DeliveryCard(
            delivery: delivery,
            onStartLoading: (lot) => _startLoading(delivery, lot),
            onStartTrip: () => _startTrip(delivery),
            onReorderLot: (oldIndex, newIndex) =>
                _controller.reorderLots(delivery.id, oldIndex, newIndex),
          );
        },
      ),
    );
  }

  Future<void> _goToLogin() async {
    await AppDependencies.sessionController.logout();
  }

  Future<void> _startLoading(DeliveryModel delivery, DeliveryLot lot) async {
    final loadingOrder = delivery.nextLoadingOrder;
    try {
      if (lot.status != DeliveryStatus.loading) {
        final updated = await _repository.startLoading(
          lot.deliveryId,
          vehicleId: lot.assignment?.vehicleId ?? delivery.assignedVehicleId,
        );
        if (updated != null) {
          _controller.updateDeliveryStatusAndPartial(
            deliveryId: delivery.id,
            status: updated.status,
            partialDelivery: updated.partialDelivery,
            balanceLots: updated.balanceLots,
            deliveredLots: updated.deliveredLots,
            totalLots: updated.totalLots,
            balanceLotNumbers: updated.balanceLotNumbers,
          );
        } else {
          _controller.markLotLoadingStarted(delivery.id, lot.deliveryId);
        }
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
            assignment: lot.assignment ?? delivery.assignment,
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
    final updated = _controller.deliveries.firstWhere(
      (item) => item.id == delivery.id,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.allLotsLoaded
              ? 'All lots loaded. You can start the trip.'
              : '${lot.clientName} loading completed.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startTrip(DeliveryModel delivery) async {
    if (delivery.tripStarted) {
      await _openTripCustomers(delivery);
      return;
    }
    if (!delivery.allLotsLoaded) return;

    await showLocationTrackingDisclosure(context);
    if (!mounted) return;

    try {
      final updated = await _repository.startTrip(
        delivery.id,
        vehicleId: delivery.assignedVehicleId,
      );
      if (updated != null) {
        _controller.updateDeliveryStatusAndPartial(
          deliveryId: delivery.id,
          status: updated.status,
          partialDelivery: updated.partialDelivery,
          balanceLots: updated.balanceLots,
          deliveredLots: updated.deliveredLots,
          totalLots: updated.totalLots,
          balanceLotNumbers: updated.balanceLotNumbers,
        );
      } else {
        _controller.markTripStarted(delivery.id);
      }
    } on Failure catch (failure) {
      _showError(failure.message);
      return;
    } catch (_) {
      _showError('Could not start the trip. Please try again.');
      return;
    }
    if (!mounted) return;

    unawaited(AppDependencies.tripLocationTracker.start(delivery.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Trip started successfully!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    final allCompleted =
        updatedLots.isNotEmpty &&
        updatedLots.every((lot) => lot.deliveryCompleted);
    if (allCompleted) {
      _controller.markDeliveryCompleted(delivery.id);
      unawaited(
        AppDependencies.tripLocationTracker.stop(deliveryId: delivery.id),
      );
    }
    final completedAStop = updatedLots.any(
      (updatedLot) =>
          updatedLot.deliveryCompleted &&
          !delivery.lots.any(
            (existingLot) =>
                existingLot.deliveryId == updatedLot.deliveryId &&
                existingLot.deliveryCompleted,
          ),
    );
    if (completedAStop) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allCompleted
                ? 'Delivery completed successfully.'
                : 'Customer delivery completed.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
