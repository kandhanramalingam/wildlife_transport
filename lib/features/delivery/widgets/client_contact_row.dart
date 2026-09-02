import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (context.mounted) {
          _showNavigationError(
            context,
            'Turn on location services to open directions.',
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          _showNavigationError(
            context,
            'Location permission is required to open directions.',
          );
        }
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final directionsUri = buildOpenStreetMapDirectionsUri(
        originLatitude: current.latitude,
        originLongitude: current.longitude,
        destinationLatitude: latitude,
        destinationLongitude: longitude,
      );
      final opened = await launchUrl(
        directionsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showNavigationError(context, 'Could not open OpenStreetMap.');
      }
    } catch (_) {
      if (context.mounted) {
        _showNavigationError(
          context,
          'Could not get your current location or open OpenStreetMap.',
        );
      }
    }
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
            tooltip: 'Directions to customer location',
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

Uri buildOpenStreetMapDirectionsUri({
  required double originLatitude,
  required double originLongitude,
  required double destinationLatitude,
  required double destinationLongitude,
}) {
  return Uri.https('www.openstreetmap.org', '/directions', {
    'engine': 'fossgis_osrm_car',
    'route':
        '$originLatitude,$originLongitude;'
        '$destinationLatitude,$destinationLongitude',
  });
}
