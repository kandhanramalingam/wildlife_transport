import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class ConnectivityMonitor {
  Future<bool> get isConnected;
  Stream<void> get onConnected;
}

class DeviceConnectivityMonitor implements ConnectivityMonitor {
  final Connectivity _connectivity;

  DeviceConnectivityMonitor([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async =>
      _hasConnection(await _connectivity.checkConnectivity());

  @override
  Stream<void> get onConnected =>
      _connectivity.onConnectivityChanged.where(_hasConnection).map((_) {});

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
