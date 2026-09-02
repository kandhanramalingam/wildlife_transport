import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/environment.dart';
import '../../../core/theme/app_theme.dart';

class CustomerLocationConfirmationSheet extends StatelessWidget {
  final String customerName;
  final double latitude;
  final double longitude;
  final double accuracyMetres;
  final bool replacingExistingLocation;

  const CustomerLocationConfirmationSheet({
    super.key,
    required this.customerName,
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.replacingExistingLocation,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              replacingExistingLocation
                  ? 'Update Customer Location'
                  : 'Confirm Customer Location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              replacingExistingLocation
                  ? 'This will replace the saved delivery pin for $customerName.'
                  : 'Save this as the delivery pin for $customerName.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 260,
                child: FlutterMap(
                  options: MapOptions(initialCenter: point, initialZoom: 16),
                  children: [
                    TileLayer(
                      urlTemplate: Environment.osmTileUrl,
                      userAgentPackageName: 'za.co.wildlifeauctions.transport',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                    SimpleAttributionWidget(
                      source: const Text('OpenStreetMap contributors'),
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'GPS accuracy: approximately ${accuracyMetres.toStringAsFixed(0)} m',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Save Pin'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
