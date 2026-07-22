import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/delivery_model.dart';
import 'steps/photos_step.dart';
import 'steps/checklist_step.dart';
import 'steps/game_loading_checklist_step.dart';
import 'steps/signature_step.dart';

class StartDeliveryScreen extends StatefulWidget {
  final DeliveryModel delivery;
  const StartDeliveryScreen({super.key, required this.delivery});

  @override
  State<StartDeliveryScreen> createState() => _StartDeliveryScreenState();
}

class _StartDeliveryScreenState extends State<StartDeliveryScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<String> _stepTitles = [
    'Photos',
    'Vehicle\nChecklist',
    'Game Loading\nChecklist',
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
                PhotosStep(onNext: _goNext),
                ChecklistStep(onNext: _goNext),
                GameLoadingChecklistStep(onNext: _goNext),
                const SignatureStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepItem(0),
          _buildConnector(0),
          _buildStepItem(1),
          _buildConnector(1),
          _buildStepItem(2),
          _buildConnector(2),
          _buildStepItem(3),
        ],
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
