import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../widgets/signature_pad_modal.dart';

class SignatureStep extends StatefulWidget {
  final Future<void> Function(Uint8List manager, Uint8List? other) onStartTrip;
  final String buttonLabel;
  final String description;
  final String incompleteMessage;
  final bool offLoadingSignatures;
  final bool requireOtherSignature;

  const SignatureStep({
    super.key,
    required this.onStartTrip,
    this.buttonLabel = 'Start Trip',
    this.description =
        'Obtain signatures from both officers before starting the trip.',
    this.incompleteMessage = 'Both signatures are required to start the trip',
    this.offLoadingSignatures = false,
    this.requireOtherSignature = true,
  });

  @override
  State<SignatureStep> createState() => _SignatureStepState();
}

class _SignatureStepState extends State<SignatureStep>
    with AutomaticKeepAliveClientMixin<SignatureStep> {
  Uint8List? _managerSignature;
  Uint8List? _officerSignature;
  bool _isSubmitting = false;

  bool get _canStart =>
      _managerSignature != null &&
      (!widget.requireOtherSignature || _officerSignature != null);

  @override
  bool get wantKeepAlive => true;

  Future<void> _openSignaturePad(
    String name,
    void Function(Uint8List) onSave,
  ) async {
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

  Future<void> _startTrip() async {
    if (_isSubmitting || !_canStart) return;
    setState(() => _isSubmitting = true);
    await widget.onStartTrip(_managerSignature!, _officerSignature);
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          Text(
            widget.description,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          _SignatureCard(
            title: widget.offLoadingSignatures ? 'Client' : 'Manager',
            subtitle: widget.offLoadingSignatures
                ? 'Person accepting the game'
                : 'Transport Manager',
            signature: _managerSignature,
            onTap: () => _openSignaturePad(
              widget.offLoadingSignatures ? 'Client' : 'Manager',
              (s) => _managerSignature = s,
            ),
          ),
          if (widget.requireOtherSignature) ...[
            const SizedBox(height: 16),
            _SignatureCard(
              title: widget.offLoadingSignatures ? 'Driver' : 'Officer',
              subtitle: widget.offLoadingSignatures
                  ? 'Driver completing the delivery'
                  : 'Supervising Officer',
              signature: _officerSignature,
              onTap: () => _openSignaturePad(
                widget.offLoadingSignatures ? 'Driver' : 'Officer',
                (s) => _officerSignature = s,
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _canStart && !_isSubmitting ? _startTrip : null,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.directions_car_outlined),
              label: Text(_isSubmitting ? 'Uploading...' : widget.buttonLabel),
            ),
          ),
          if (!_canStart)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  widget.incompleteMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
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
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: AppTheme.primary,
                ),
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
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 22,
                  ),
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
                      Icon(
                        Icons.draw_outlined,
                        color: AppTheme.textSecondary,
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to sign',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
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
