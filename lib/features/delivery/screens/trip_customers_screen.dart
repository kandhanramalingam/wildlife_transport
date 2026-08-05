import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/delivery_repository.dart';
import '../models/delivery_model.dart';
import 'start_delivery/start_delivery_screen.dart';

class TripCustomersScreen extends StatefulWidget {
  final DeliveryModel delivery;

  const TripCustomersScreen({super.key, required this.delivery});

  @override
  State<TripCustomersScreen> createState() => _TripCustomersScreenState();
}

class _TripCustomersScreenState extends State<TripCustomersScreen> {
  late final DeliveryRepository _repository;
  List<DeliveryCustomer> _customers = const [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get _allCompleted =>
      _customers.isNotEmpty &&
      _customers.every((customer) => customer.completed);

  @override
  void initState() {
    super.initState();
    _repository = AppDependencies.createDeliveryRepository();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final customers = await _repository.getDeliveryCustomers(
        widget.delivery.id,
      );
      if (!mounted) return;
      setState(() => _customers = customers);
    } on Failure catch (failure) {
      if (mounted) setState(() => _errorMessage = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Could not load customers. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startOffLoading(DeliveryCustomer customer) async {
    if (customer.completed) return;

    final customerDelivery = DeliveryModel(
      id: customer.deliveryId,
      buyerId: customer.buyerId,
      auctionId: widget.delivery.auctionId,
      dateTime: widget.delivery.dateTime,
      clientName: customer.clientName,
      clientAddress: widget.delivery.clientAddress,
      status: DeliveryStatus.inProgress,
      paymentStatus: widget.delivery.paymentStatus,
    );
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StartDeliveryScreen(
          delivery: customerDelivery,
          workflow: DeliveryWorkflow.arrival,
        ),
      ),
    );
    if (completed != true || !mounted) return;

    setState(() {
      _customers = _customers
          .map(
            (item) => item.deliveryId == customer.deliveryId
                ? item.copyWith(completed: true)
                : item,
          )
          .toList(growable: false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _allCompleted
              ? 'All customer deliveries completed.'
              : 'Customer delivery completed. Continue to the next customer.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _close() {
    Navigator.of(context).pop(_allCompleted);
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
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCustomers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_customers.isEmpty) {
      return const Center(child: Text('No customer delivery found'));
    }

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _customers.length,
        itemBuilder: (context, index) {
          final customer = _customers[index];
          return _CustomerCard(
            customer: customer,
            onArrived: () => _startOffLoading(customer),
          );
        },
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final DeliveryCustomer customer;
  final VoidCallback onArrived;

  const _CustomerCard({required this.customer, required this.onArrived});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: AppTheme.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.clientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (customer.mainBuyer) ...[
                        const SizedBox(height: 3),
                        const Text(
                          'Main buyer',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (customer.completed)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (!customer.completed) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onArrived,
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Arrived at Location'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
