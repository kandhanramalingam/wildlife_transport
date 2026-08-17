import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/delivery_repository.dart';
import '../../models/delivery_model.dart';
import '../../models/start_delivery_submission.dart';
import 'steps/photos_step.dart';
import 'steps/checklist_step.dart';
import 'steps/game_loading_checklist_step.dart';
import 'steps/signature_step.dart';

enum DeliveryWorkflow { startTrip, arrival }

class StartDeliveryScreen extends StatefulWidget {
  final DeliveryModel delivery;
  final DeliveryWorkflow workflow;

  const StartDeliveryScreen({
    super.key,
    required this.delivery,
    this.workflow = DeliveryWorkflow.startTrip,
  });

  @override
  State<StartDeliveryScreen> createState() => _StartDeliveryScreenState();
}

class _StartDeliveryScreenState extends State<StartDeliveryScreen> {
  final PageController _pageController = PageController();
  late final DeliveryRepository _repository;
  int _currentStep = 0;
  PhotosStepData? _photos;
  List<DeliveryChecklistItem>? _vehicleChecklist;
  List<DeliveryChecklistItem>? _gameLoadingChecklist;

  @override
  void initState() {
    super.initState();
    _repository = AppDependencies.createDeliveryRepository();
  }

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
                  includeAnimalPhotos: !_isArrival,
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
        ],
      ),
    );
  }

  Future<void> _finishWorkflow(
    Uint8List managerSignature,
    Uint8List? otherSignature,
  ) async {
    if (_isArrival) {
      final photos = _photos;
      final offLoadChecklist = _gameLoadingChecklist;
      final buyerId = widget.delivery.buyerId?.trim() ?? '';
      if (photos == null ||
          offLoadChecklist == null ||
          photos.odometerReading == null ||
          buyerId.isEmpty) {
        _showError('Some off-loading details are missing. Please try again.');
        return;
      }
      try {
        await _repository.completeOffloading(
          widget.delivery.id,
          CompleteOffloadingSubmission(
            offLoadAnimalsVideo: photos.animalVideo,
            offLoadChecklist: offLoadChecklist,
            clientSignature: managerSignature,
            endOdometerReading: photos.odometerReading!,
            buyerId: buyerId,
          ),
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
