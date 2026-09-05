import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/environment.dart';
import 'maps_loader.dart';

/// Shared embedded map. Disables Google's external directions toolbar.
class DeliveryGoogleMap extends StatefulWidget {
  final LatLng target;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool showMyLocation;
  final ValueChanged<GoogleMapController>? onMapCreated;
  const DeliveryGoogleMap({
    super.key,
    required this.target,
    this.markers = const {},
    this.polylines = const {},
    this.showMyLocation = false,
    this.onMapCreated,
  });

  @override
  State<DeliveryGoogleMap> createState() => _DeliveryGoogleMapState();
}

class _DeliveryGoogleMapState extends State<DeliveryGoogleMap> {
  late Future<void> _ready;
  @override
  void initState() {
    super.initState();
    _ready = Environment.googleMapsApiKey.isEmpty
        ? Future.value()
        : loadGoogleMaps(Environment.googleMapsApiKey);
  }

  BitmapDescriptor _advancedIcon(BitmapDescriptor icon) {
    final config = icon.toJson();
    if (config is List && config.isNotEmpty && config.first == 'defaultMarker') {
      final hue = config.length > 1 ? (config[1] as num).toDouble() : 0.0;
      return PinConfig(
        backgroundColor: HSVColor.fromAHSV(1, hue, 0.85, 0.9).toColor(),
        borderColor: Colors.white,
      );
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    if (Environment.googleMapsApiKey.isEmpty) {
      return const Center(
        child: Text(
          'Google Maps is not configured yet.',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return const Center(
        child: Text('Maps are available on Android, iOS and web.'),
      );
    }
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() {
                _ready = loadGoogleMaps(Environment.googleMapsApiKey);
              }),
              child: const Text('Map could not load. Retry'),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.target,
            zoom: 16,
          ),
          mapId: kIsWeb ? Environment.googleMapsWebMapId : null,
          markerType: kIsWeb
              ? GoogleMapMarkerType.advancedMarker
              : GoogleMapMarkerType.marker,
          markers: kIsWeb
              ? widget.markers
                    .map(
                      (marker) => AdvancedMarker(
                        markerId: marker.markerId,
                        position: marker.position,
                        icon: _advancedIcon(marker.icon),
                        infoWindow: marker.infoWindow,
                        alpha: marker.alpha,
                        anchor: marker.anchor,
                        consumeTapEvents: marker.consumeTapEvents,
                        draggable: marker.draggable,
                        flat: marker.flat,
                        rotation: marker.rotation,
                        visible: marker.visible,
                        zIndex: marker.zIndexInt,
                        clusterManagerId: marker.clusterManagerId,
                        onTap: marker.onTap,
                        onDrag: marker.onDrag,
                        onDragStart: marker.onDragStart,
                        onDragEnd: marker.onDragEnd,
                      ),
                    )
                    .toSet()
              : widget.markers,
          polylines: widget.polylines,
          myLocationEnabled: widget.showMyLocation,
          myLocationButtonEnabled: widget.showMyLocation,
          mapToolbarEnabled: false,
          onMapCreated: widget.onMapCreated,
        );
      },
    );
  }
}
