import 'package:google_maps_flutter/google_maps_flutter.dart';

class DrivingRoute {
  final List<LatLng> points;
  final double distanceMetres;
  final double durationSeconds;
  final List<String> instructions;
  final List<String> warnings;
  final List<DrivingStep> steps;
  const DrivingRoute({
    required this.points,
    required this.distanceMetres,
    required this.durationSeconds,
    required this.instructions,
    required this.warnings,
    this.steps = const [],
  });

  factory DrivingRoute.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as List;
    final points = coordinates
        .map((value) {
          final pair = value as List;
          final lat = (pair[1] as num).toDouble();
          final lng = (pair[0] as num).toDouble();
          if (!lat.isFinite ||
              !lng.isFinite ||
              lat.abs() > 90 ||
              lng.abs() > 180) {
            throw const FormatException('Invalid route coordinates');
          }
          return LatLng(lat, lng);
        })
        .toList(growable: false);
    if (points.length < 2) {
      throw const FormatException('No driving route found');
    }
    return DrivingRoute(
      points: points,
      distanceMetres: (json['distanceMetres'] as num).toDouble(),
      durationSeconds: (json['durationSeconds'] as num).toDouble(),
      instructions: (json['instructions'] as List).cast<String>(),
      warnings: (json['warnings'] as List? ?? []).cast<String>(),
      steps: (json['steps'] as List? ?? [])
          .map(
            (s) => DrivingStep(
              instruction: s['instruction'] as String,
              distanceMetres: (s['distanceMetres'] as num).toDouble(),
              maneuver: s['maneuver'] as String? ?? 'STRAIGHT',
            ),
          )
          .toList(),
    );
  }
}

class DrivingStep {
  final String instruction;
  final double distanceMetres;
  final String maneuver;
  const DrivingStep({
    required this.instruction,
    required this.distanceMetres,
    this.maneuver = 'STRAIGHT',
  });
}
