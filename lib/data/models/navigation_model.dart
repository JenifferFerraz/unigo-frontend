import 'package:latlong2/latlong.dart';

class NavigationRoute {
  final List<NavigationStep> steps;
  final double totalDistance; // in meters
  final int estimatedDuration; // in seconds

  NavigationRoute({
    required this.steps,
    required this.totalDistance,
    required this.estimatedDuration,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    return NavigationRoute(
      steps: (json['steps'] as List).map((step) => NavigationStep.fromJson(step)).toList(),
      totalDistance: json['totalDistance'],
      estimatedDuration: json['estimatedDuration'],
    );
  }
}

class NavigationStep {
  final String instruction;
  final LatLng startPoint;
  final LatLng endPoint;
  final double distance; // in meters
  final int duration; // in seconds
  final String maneuver; // turn type: straight, left, right, etc.
  final double? heading;

  NavigationStep({
    required this.instruction,
    required this.startPoint,
    required this.endPoint,
    required this.distance,
    required this.duration,
    required this.maneuver,
    this.heading,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    return NavigationStep(
      instruction: json['instruction'],
      startPoint: LatLng(json['startPoint'][0], json['startPoint'][1]),
      endPoint: LatLng(json['endPoint'][0], json['endPoint'][1]),
      distance: json['distance'],
      duration: json['duration'],
      maneuver: json['maneuver'],
      heading: json['heading'],
    );
  }
}

// For accessibility features
enum VoiceGuidanceLevel {
  off,
  basic,
  detailed,
}

// For tracking navigation progress
class NavigationProgress {
  final int currentStepIndex;
  final double distanceToNextStep; // in meters
  final double distanceToDestination; // in meters
  final int estimatedTimeRemaining; // in seconds

  NavigationProgress({
    required this.currentStepIndex,
    required this.distanceToNextStep,
    required this.distanceToDestination,
    required this.estimatedTimeRemaining,
  });
}
