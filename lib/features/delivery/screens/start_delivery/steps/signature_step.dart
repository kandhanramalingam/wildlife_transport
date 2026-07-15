import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../widgets/signature_pad_modal.dart';

class SignatureStep extends StatefulWidget {
  const SignatureStep({super.key});

  @override
  State<SignatureStep> createState() => _SignatureStepState();
}

class _SignatureStepState extends State<SignatureStep> {
  Uint8List? _managerSignature;
  Uint8List? _officerSignature;

  bool get _canStart => _managerSignature != null && _officerSignature != null;

  Future<void> _openSignaturePad(String name, void Function(Uint8List) onSave) async {
    final result = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SignaturePadModal(signerName: name),
    );
    if (result != null) setState(() => onSave(result));
  }

  void _startTrip() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Trip started successfully!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Required Signatures',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Obtain signatures from both officers before starting the trip.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          _SignatureCard(
            title: 'Manager',
            subtitle: 'Transport Manager',
            signature: _managerSignature,
            onTap: () => _openSignaturePad(
              'Manager',
              (s) => _managerSignature = s,
            ),
          ),
          const SizedBox(height: 16),
          _SignatureCard(
            title: 'Officer',
            subtitle: 'Supervising Officer',
            signature: _officerSignature,
            onTap: () => _openSignaturePad(
              'Officer',
              (s) => _officerSignature = s,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _canStart ? _startTrip : null,
              icon: const Icon(Icons.directions_car_outlined),
              label: const Text('Start Trip'),
            ),
          ),
          if (!_canStart)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  'Both signatures are required to start the trip',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Uint8List? signature;
  final VoidCallback onTap;

  const _SignatureCard({
    required this.title,
    required this.subtitle,
    required this.signature,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (signature != null)
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            if (signature != null) ...[
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(signature!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text('Re-sign', style: TextStyle(fontSize: 13)),
                ),
              ),
            ] else
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.draw_outlined,
                          color: AppTheme.textSecondary, size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Tap to sign',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
