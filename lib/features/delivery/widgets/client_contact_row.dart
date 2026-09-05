import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/customer_directions_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class ClientContactRow extends StatelessWidget {
  final String contactNumber;
  final double fontSize;
  final String destinationLatitude;
  final String destinationLongitude;
  final bool showNavigation;

  const ClientContactRow({
    super.key,
    required this.contactNumber,
    this.fontSize = 13,
    this.destinationLatitude = '',
    this.destinationLongitude = '',
    this.showNavigation = false,
  });

  Future<void> _openDialer(BuildContext context) async {
    final dialNumber = contactNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (dialNumber.isEmpty) return;

    try {
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: dialNumber),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showDialerError(context);
      }
    } catch (_) {
      if (context.mounted) _showDialerError(context);
    }
  }

  void _showDialerError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the phone dialer.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final latitude = double.tryParse(destinationLatitude.trim());
    final longitude = double.tryParse(destinationLongitude.trim());
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      _showNavigationError(
        context,
        'Customer latitude and longitude are unavailable.',
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CustomerDirectionsScreen(latitude: latitude, longitude: longitude),
      ),
    );
  }

  void _showNavigationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.phone_outlined,
          size: 18,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Contact: $contactNumber',
            style: TextStyle(
              fontSize: fontSize,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        IconButton.filled(
          onPressed: () => _openDialer(context),
          icon: const Icon(Icons.call_rounded, size: 19),
          tooltip: 'Call $contactNumber',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            fixedSize: const Size(38, 38),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: null,
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
          tooltip: 'WhatsApp (coming soon)',
          style: IconButton.styleFrom(
            disabledForegroundColor: const Color(0xFFAAAAAA),
            fixedSize: const Size(38, 38),
            padding: EdgeInsets.zero,
            side: const BorderSide(color: Color(0xFFD0D0D0)),
          ),
        ),
        if (showNavigation) ...[
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _openDirections(context),
            icon: const Icon(Icons.directions_outlined, size: 20),
            tooltip: 'Open Google Maps directions',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              fixedSize: const Size(38, 38),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );
  }
}
