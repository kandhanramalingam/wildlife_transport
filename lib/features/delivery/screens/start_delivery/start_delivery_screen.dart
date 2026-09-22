import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/document_preview.dart';
import '../../domain/delivery_repository.dart';
import '../../models/delivery_model.dart';
import '../../models/start_delivery_submission.dart';
import '../customer_directions_screen.dart';
import '../trip_customers_screen.dart' show resolveInvoiceUri;
import 'steps/photos_step.dart';
import 'steps/checklist_step.dart';
import 'steps/game_loading_checklist_step.dart';
import 'steps/signature_step.dart';

enum DeliveryWorkflow { startTrip, arrival }

class StartDeliveryScreen extends StatefulWidget {
  final DeliveryModel delivery;
  final DeliveryWorkflow workflow;
  final String destinationLatitude;
  final String destinationLongitude;

  const StartDeliveryScreen({
    super.key,
    required this.delivery,
    this.workflow = DeliveryWorkflow.startTrip,
    this.destinationLatitude = '',
    this.destinationLongitude = '',
  });

  @override
  State<StartDeliveryScreen> createState() => _StartDeliveryScreenState();
}

class _StartDeliveryScreenState extends State<StartDeliveryScreen> {
  final PageController _pageController = PageController();
  late final DeliveryRepository _repository =
      AppDependencies.createDeliveryRepository();
  int _currentStep = 0;
  PhotosStepData? _photos;
  List<DeliveryChecklistItem>? _vehicleChecklist;
  List<DeliveryChecklistItem>? _gameLoadingChecklist;

  bool get _isArrival => widget.workflow == DeliveryWorkflow.arrival;

  List<String> get _stepTitles => _isArrival
      ? ['Off Loading\nChecklist', 'Video &\nOdometer', 'Client\nSignature']
      : [
          'Vehicle\nChecklist',
          'Game Loading\nChecklist',
          'Photos',
          'Signatures',
        ];

  void _goNext() {
    if (_currentStep < _stepTitles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _goBack),
        title: Text(widget.delivery.clientName),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  top: _isArrival ? 68 : 0,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      if (!_isArrival)
                        ChecklistStep(
                          onNext: (items) {
                            _vehicleChecklist = items;
                            _goNext();
                          },
                        ),
                      GameLoadingChecklistStep(
                        onNext: (items) {
                          _gameLoadingChecklist = items;
                          _goNext();
                        },
                        isOffLoading: _isArrival,
                      ),
                      PhotosStep(
                        onNext: (data) {
                          _photos = data;
                          _goNext();
                        },
                        includeVehicleDetails: true,
                        includeVehiclePhotos: !_isArrival,
                        includeAnimalPhotos: true,
                        requireLocation: !_isArrival,
                        isOffLoading: _isArrival,
                      ),
                      SignatureStep(
                        onStartTrip: _finishWorkflow,
                        buttonLabel: _isArrival
                            ? 'Complete Off-loading'
                            : 'Complete Loading',
                        offLoadingSignatures: _isArrival,
                        requireOtherSignature: !_isArrival,
                        description: _isArrival
                            ? 'The client must sign to confirm the animals’ health and quantities.'
                            : 'Obtain signatures from both officers to complete this lot’s loading.',
                        incompleteMessage: _isArrival
                            ? 'The client signature is required to complete off-loading'
                            : 'Both signatures are required to complete loading',
                      ),
                    ],
                  ),
                ),
                if (_isArrival)
                  Positioned(top: 8, right: 16, child: _buildQuickActions()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: null,
          tooltip: 'View invoice PDF',
          onPressed: _openInvoice,
          child: const Icon(Icons.picture_as_pdf_outlined),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: null,
          tooltip: 'View permits',
          onPressed: _openPermits,
          child: const Icon(Icons.description_outlined),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: null,
          tooltip: 'Open navigation',
          onPressed: _openNavigation,
          child: const Icon(Icons.directions_outlined),
        ),
      ],
    );
  }

  Future<void> _openInvoice() async {
    final path = widget.delivery.invoicePath?.trim() ?? '';
    if (path.isEmpty) {
      _showError('Invoice PDF is not available for this customer.');
      return;
    }
    await _openDocument(path, 'Invoice');
  }

  Future<void> _openPermits() async {
    final permits = widget.delivery.permits;
    if (permits.isEmpty) {
      _showError('No permits are available for this trip.');
      return;
    }
    if (permits.length == 1) {
      await _openDocument(permits.first, 'Permit');
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var index = 0; index < permits.length; index++)
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('Permit ${index + 1}'),
                onTap: () => Navigator.of(sheetContext).pop(permits[index]),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) await _openDocument(selected, 'Permit');
  }

  Future<void> _openDocument(String path, String fallbackTitle) async {
    try {
      final uri = resolveInvoiceUri(Environment.apiBaseUrl, path);
      await showDocumentPreview(
        context,
        title: uri.pathSegments.lastOrNull?.isNotEmpty == true
            ? uri.pathSegments.last
            : fallbackTitle,
        uri: uri,
      );
    } catch (_) {
      if (mounted) {
        _showError('Could not open the ${fallbackTitle.toLowerCase()}.');
      }
    }
  }

  Future<void> _openNavigation() async {
    final latitude = double.tryParse(widget.destinationLatitude.trim());
    final longitude = double.tryParse(widget.destinationLongitude.trim());
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      _showError('Customer latitude and longitude are unavailable.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CustomerDirectionsScreen(latitude: latitude, longitude: longitude),
      ),
    );
  }

  Future<void> _finishWorkflow(
    Uint8List managerSignature,
    Uint8List? otherSignature, {
    String? clientComment,
  }) async {
    if (_isArrival) {
      final photos = _photos;
      final offLoadChecklist = _gameLoadingChecklist;
      final buyerId = widget.delivery.buyerId?.trim() ?? '';
      if (photos == null ||
          offLoadChecklist == null ||
          photos.odometerReading == null ||
          photos.animalPhotos.isEmpty ||
          buyerId.isEmpty) {
        _showError('Some off-loading details are missing. Please try again.');
        return;
      }
      try {
        await _repository.completeOffloading(
          widget.delivery.id,
          CompleteOffloadingSubmission(
            endAnimalPhotos: photos.animalPhotos,
            endAnimalVideos: photos.animalVideo,
            offLoadChecklist: offLoadChecklist,
            clientSignature: managerSignature,
            endOdometerReading: photos.odometerReading!,
            buyerId: buyerId,
            clientComment: clientComment,
          ),
          vehicleId: widget.delivery.assignedVehicleId,
        );
        if (mounted) Navigator.of(context).pop(true);
      } on Failure catch (failure) {
        _showError(failure.message);
      } catch (_) {
        _showError('Could not complete off-loading. Please try again.');
      }
      return;
    }

    final photos = _photos;
    final vehicleChecklist = _vehicleChecklist;
    final gameLoadingChecklist = _gameLoadingChecklist;
    if (photos == null ||
        vehicleChecklist == null ||
        gameLoadingChecklist == null ||
        otherSignature == null ||
        photos.odometerReading == null) {
      _showError('Some start-delivery details are missing. Please try again.');
      return;
    }

    try {
      await _repository.completeLoading(
        widget.delivery.id,
        StartDeliverySubmission(
          startOdometerReading: photos.odometerReading!,
          startVehiclePhotos: photos.vehiclePhotos,
          startAnimalPhotos: photos.animalPhotos,
          onLoadAnimalsVideo: photos.animalVideo,
          startLatitude: photos.latitude,
          startLongitude: photos.longitude,
          vehicleChecklist: vehicleChecklist,
          gameLoadingChecklist: gameLoadingChecklist,
          managerSignature: managerSignature,
          otherSignature: otherSignature,
        ),
        vehicleId: widget.delivery.assignedVehicleId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Failure catch (failure) {
      _showError(failure.message);
    } catch (_) {
      _showError('Could not complete loading. Please try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildStepper() {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_stepTitles.length * 2 - 1, (index) {
          if (index.isEven) return _buildStepItem(index ~/ 2);
          return _buildConnector(index ~/ 2);
        }),
      ),
    );
  }

  Widget _buildStepItem(int index) {
    final isActive = index == _currentStep;
    final isDone = index < _currentStep;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isDone ? Colors.white : Colors.white24,
          ),
          alignment: Alignment.center,
          child: isDone
              ? Icon(Icons.check, size: 16, color: AppTheme.primary)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppTheme.primary : Colors.white60,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          _stepTitles[index],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: isActive || isDone ? Colors.white : Colors.white54,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int index) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: index < _currentStep ? Colors.white : Colors.white30,
      ),
    );
  }
}
