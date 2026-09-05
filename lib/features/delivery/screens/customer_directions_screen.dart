import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/maps/delivery_google_map.dart';
import '../models/driving_route.dart';
import '../presentation/customer_navigation_controller.dart';

class CustomerDirectionsScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final CustomerNavigationController? controller;
  const CustomerDirectionsScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.controller,
  });

  @override
  State<CustomerDirectionsScreen> createState() =>
      _CustomerDirectionsScreenState();
}

class _CustomerDirectionsScreenState extends State<CustomerDirectionsScreen> {
  GoogleMapController? _map;
  late final CustomerNavigationController _navigation;
  final _cancel = CancelToken();
  DrivingRoute? _displayedRoute;
  LatLng? _lastCameraPosition;
  bool _follow = true;
  LatLng get _destination => LatLng(widget.latitude, widget.longitude);

  @override
  void initState() {
    super.initState();
    _navigation =
        widget.controller ??
        CustomerNavigationController(
          destination: _destination,
          loadRoute: (origin, destination) async {
            final response = await AppDependencies.apiClient.dio
                .post<Map<String, dynamic>>(
                  'driver-auth/directions',
                  cancelToken: _cancel,
                  data: {
                    'originLatitude': origin.latitude,
                    'originLongitude': origin.longitude,
                    'destinationLatitude': destination.latitude,
                    'destinationLongitude': destination.longitude,
                  },
                );
            return DrivingRoute.fromJson(response.data!);
          },
        );
    _navigation.addListener(_changed);
    _navigation.refresh();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    final route = _navigation.route;
    if (_navigation.navigating &&
        _follow &&
        _navigation.position != _lastCameraPosition) {
      _lastCameraPosition = _navigation.position;
      _moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _navigation.position!,
            zoom: 17,
            bearing: _navigation.heading,
            tilt: 45,
          ),
        ),
      );
    } else if (!_navigation.navigating && route != _displayedRoute) {
      _displayedRoute = route;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
    }
  }

  Future<void> _moveCamera(CameraUpdate update) async {
    try {
      await _map?.animateCamera(update);
    } catch (_) {
      /* Map may be closing. */
    }
  }

  void _fitRoute() {
    final points = _navigation.route?.points;
    if (!mounted || points == null || points.isEmpty) return;
    _moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            points.map((p) => p.latitude).reduce(math.min),
            points.map((p) => p.longitude).reduce(math.min),
          ),
          northeast: LatLng(
            points.map((p) => p.latitude).reduce(math.max),
            points.map((p) => p.longitude).reduce(math.max),
          ),
        ),
        40,
      ),
    );
  }

  @override
  void dispose() {
    _navigation.removeListener(_changed);
    _navigation.stop();
    if (widget.controller == null) _navigation.dispose();
    _cancel.cancel();
    _map = null;
    super.dispose();
  }

  String _distance(double metres) => metres < 1000
      ? '${metres.round()} m'
      : '${(metres / 1000).toStringAsFixed(1)} km';

  Future<void> _openGoogleMaps() async {
    try {
      final opened = await launchUrl(
        googleMapsDirectionsUri(_destination),
        mode: LaunchMode.externalApplication,
      );
      if (opened || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps on this device.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSteps() {
    final route = _navigation.route;
    if (route == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Driving directions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final warning in route.warnings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(warning),
              ),
            if (route.steps.isNotEmpty)
              for (var i = 0; i < route.steps.length; i++)
                ListTile(
                  leading: Text('${i + 1}.'),
                  title: Text(route.steps[i].instruction),
                  subtitle: Text(_distance(route.steps[i].distanceMetres)),
                )
            else
              for (final instruction in route.instructions)
                ListTile(title: Text(instruction)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = _navigation;
    final route = nav.route;
    final eta = DateTime.now().add(
      Duration(seconds: nav.remainingSeconds.round()),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directions'),
        actions: [
          IconButton(
            onPressed: nav.loading ? null : nav.refresh,
            tooltip: 'Refresh route from current location',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DeliveryGoogleMap(
              target: _destination,
              showMyLocation: nav.position != null,
              markers: {
                Marker(
                  markerId: const MarkerId('destination'),
                  position: _destination,
                  infoWindow: const InfoWindow(
                    title: 'Customer delivery location',
                  ),
                ),
                if (nav.position != null)
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: nav.position!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: const InfoWindow(
                      title: 'Driver current location',
                    ),
                  ),
              },
              polylines: {
                if (route != null)
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: route.points,
                    color: Colors.blue,
                    width: 6,
                  ),
              },
              onMapCreated: (controller) {
                _map = controller;
                _fitRoute();
              },
            ),
          ),
          if (nav.loading) const LinearProgressIndicator(),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (nav.error != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nav.error!,
                            style: const TextStyle(color: Colors.deepOrange),
                          ),
                        ),
                        TextButton(
                          onPressed: nav.loading ? null : nav.refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  Text(
                    nav.arrived
                        ? 'Customer location reached'
                        : route == null
                        ? 'Route to customer'
                        : '${_distance(nav.remainingMetres)} • ${(nav.remainingSeconds / 60).ceil()} min',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    route == null
                        ? (nav.loading
                              ? 'Getting current location and driving directions…'
                              : 'Distance and arrival time will appear when the route is ready.')
                        : nav.arrived
                        ? 'Return to the delivery to confirm arrival.'
                        : 'Estimated arrival ${TimeOfDay.fromDateTime(eta).format(context)} • From your current location',
                  ),
                  if (route != null && !nav.arrived)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.navigation, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_distance(nav.stepRemainingMetres)} • ${nav.instruction}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (route == null && nav.error != null) ...[
                    OutlinedButton.icon(
                      onPressed: _openGoogleMaps,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Open in Google Maps'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (nav.arrived)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to delivery'),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: nav.navigating
                                ? nav.stop
                                : nav.loading || route == null
                                ? null
                                : () {
                                    _follow = true;
                                    _lastCameraPosition = null;
                                    nav.start();
                                  },
                            icon: Icon(
                              nav.navigating ? Icons.stop : Icons.navigation,
                            ),
                            label: Text(
                              nav.navigating
                                  ? 'Stop navigation'
                                  : 'Start navigation',
                            ),
                          ),
                        ),
                        if (route != null)
                          IconButton(
                            onPressed: _showSteps,
                            tooltip: 'All directions',
                            icon: const Icon(Icons.list),
                          ),
                        if (nav.navigating)
                          IconButton(
                            onPressed: () {
                              setState(() => _follow = !_follow);
                              if (_follow) {
                                _lastCameraPosition = null;
                                _changed();
                              } else {
                                _fitRoute();
                              }
                            },
                            tooltip: _follow
                                ? 'Route overview'
                                : 'Follow driver',
                            icon: Icon(
                              _follow ? Icons.route : Icons.my_location,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Uri googleMapsDirectionsUri(LatLng destination) =>
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destination.latitude},${destination.longitude}',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });
