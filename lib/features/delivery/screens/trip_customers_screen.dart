import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/environment.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/delivery_repository.dart';
import '../models/delivery_model.dart';
import '../widgets/client_contact_row.dart';
import 'start_delivery/start_delivery_screen.dart';

class TripCustomersScreen extends StatefulWidget {
  final DeliveryModel delivery;

  const TripCustomersScreen({super.key, required this.delivery});

  @override
  State<TripCustomersScreen> createState() => _TripCustomersScreenState();
}

class _TripCustomersScreenState extends State<TripCustomersScreen> {
  late List<DeliveryLot> _customers;
  DeliveryRepository? _repository;
  String? _activeCustomerDeliveryId;
  String? _startingOffloadingDeliveryId;

  bool get _allCompleted =>
      _customers.isNotEmpty &&
      _customers.every((customer) => customer.deliveryCompleted);

  @override
  void initState() {
    super.initState();
    _customers = widget.delivery.lots.isEmpty
        ? [
            DeliveryLot(
              clientName: widget.delivery.clientName,
              buyerId: widget.delivery.buyerId ?? '',
              mainBuyer: true,
              deliveryId: widget.delivery.id,
              address: widget.delivery.clientAddress,
              invoicePath: widget.delivery.invoicePath,
              status: DeliveryStatus.inProgress,
            ),
          ]
        : List.of(widget.delivery.lotsInOffloadingOrder);
    for (final customer in _customers) {
      if (customer.atDeliveryPoint && !customer.deliveryCompleted) {
        _activeCustomerDeliveryId = customer.deliveryId;
        break;
      }
    }
  }

  Future<void> _startOffLoading(DeliveryLot customer) async {
    if (customer.deliveryCompleted) return;
    final activeDeliveryId = _activeCustomerDeliveryId;
    if (activeDeliveryId != null && activeDeliveryId != customer.deliveryId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Finish the current buyer’s off-loading before starting another.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_activeCustomerDeliveryId == null) {
      setState(() {
        _activeCustomerDeliveryId = customer.deliveryId;
        _customers = _customers
            .map(
              (item) => item.deliveryId == customer.deliveryId
                  ? item.copyWith(atDeliveryPoint: true)
                  : item,
            )
            .toList(growable: false);
      });
      return;
    }

    if (_startingOffloadingDeliveryId == customer.deliveryId) return;
    if (customer.status != DeliveryStatus.offloading) {
      setState(() => _startingOffloadingDeliveryId = customer.deliveryId);
      try {
        await (_repository ??= AppDependencies.createDeliveryRepository())
            .startOffloading(customer.deliveryId);
      } on Failure catch (failure) {
        _showError(failure.message);
        return;
      } catch (_) {
        _showError('Could not start off-loading. Please try again.');
        return;
      } finally {
        if (mounted) setState(() => _startingOffloadingDeliveryId = null);
      }
      if (!mounted) return;
      setState(() {
        _customers = _customers
            .map(
              (item) => item.deliveryId == customer.deliveryId
                  ? item.copyWith(status: DeliveryStatus.offloading)
                  : item,
            )
            .toList(growable: false);
      });
    }

    final customerDelivery = DeliveryModel(
      id: customer.deliveryId,
      buyerId: customer.buyerId,
      auctionId: widget.delivery.auctionId,
      dateTime: widget.delivery.dateTime,
      clientName: customer.clientName,
      clientAddress: customer.address,
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
      _activeCustomerDeliveryId = null;
      _customers = _customers
          .map(
            (item) => item.deliveryId == customer.deliveryId
                ? item.copyWith(
                    status: DeliveryStatus.completed,
                    atDeliveryPoint: false,
                  )
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
    Navigator.of(context).pop(List<DeliveryLot>.unmodifiable(_customers));
  }

  Future<void> _viewInvoice(DeliveryLot customer) async {
    final invoicePath = customer.invoicePathValue;
    if (invoicePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice PDF is not available for this customer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final invoiceUri = resolveInvoiceUri(Environment.apiBaseUrl, invoicePath);
      final opened = await launchUrl(
        invoiceUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showInvoiceError();
    } catch (_) {
      if (mounted) _showInvoiceError();
    }
  }

  void _showInvoiceError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the invoice PDF.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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
    if (_customers.isEmpty) {
      return const Center(child: Text('No customer delivery found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final customer = _customers[index];
        final isActive = _activeCustomerDeliveryId == customer.deliveryId;
        final isLocked = _activeCustomerDeliveryId != null && !isActive;
        final isStarting = _startingOffloadingDeliveryId == customer.deliveryId;
        return _CustomerCard(
          customer: customer,
          isActive: isActive,
          isLocked: isLocked,
          isStarting: isStarting,
          onArrived: () => _startOffLoading(customer),
          onViewInvoice: () => _viewInvoice(customer),
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final DeliveryLot customer;
  final bool isActive;
  final bool isLocked;
  final bool isStarting;
  final VoidCallback onArrived;
  final VoidCallback onViewInvoice;

  const _CustomerCard({
    required this.customer,
    required this.isActive,
    required this.isLocked,
    required this.isStarting,
    required this.onArrived,
    required this.onViewInvoice,
  });

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
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onViewInvoice,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  color: !customer.hasInvoice
                      ? AppTheme.textSecondary
                      : AppTheme.primary,
                  tooltip: !customer.hasInvoice
                      ? 'Invoice PDF unavailable'
                      : 'View invoice PDF',
                ),
                if (customer.deliveryCompleted)
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
            if (customer.address.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer.address,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            if (customer.farmName.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ClientDetailRow(
                icon: Icons.agriculture_outlined,
                value: 'Farm: ${customer.farmName}',
              ),
            ],
            if (customer.companyName.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ClientDetailRow(
                icon: Icons.business_outlined,
                value: 'Company: ${customer.companyName}',
              ),
            ],
            if (customer.contactNumber.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClientContactRow(
                contactNumber: customer.contactNumber,
                fontSize: 14,
                destinationLatitude: customer.latitude,
                destinationLongitude: customer.longitude,
                showNavigation: true,
              ),
            ],
            if (customer.latitude.isNotEmpty ||
                customer.longitude.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ClientDetailRow(
                icon: Icons.my_location_outlined,
                value: [
                  if (customer.latitude.isNotEmpty) 'Lat: ${customer.latitude}',
                  if (customer.longitude.isNotEmpty)
                    'Long: ${customer.longitude}',
                ].join('  •  '),
              ),
            ],
            if (!customer.deliveryCompleted) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: isLocked || isStarting ? null : onArrived,
                  icon: Icon(
                    isStarting
                        ? Icons.hourglass_top
                        : isLocked
                        ? Icons.lock_outline
                        : isActive
                        ? Icons.play_arrow
                        : Icons.location_on_outlined,
                  ),
                  label: Text(
                    isStarting
                        ? 'Starting Off-loading...'
                        : isLocked
                        ? 'Finish Current Off-loading First'
                        : isActive
                        ? 'Begin Offloading'
                        : 'At delivery point',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Uri resolveInvoiceUri(String apiBaseUrl, String invoicePath) {
  final trimmedPath = invoicePath.trim();
  final parsedPath = Uri.tryParse(trimmedPath);
  if (parsedPath != null && parsedPath.hasScheme) return parsedPath;
  return Uri.parse(apiBaseUrl).resolve(trimmedPath);
}

class _ClientDetailRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ClientDetailRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
