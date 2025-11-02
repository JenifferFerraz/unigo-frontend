import 'package:latlong2/latlong.dart';

class NavigationRoute {
  List<LatLng>? path;
  List<LatLng>? get computedPath {
    if (steps.isEmpty) return null;
    return [
      ...steps.expand((step) => [step.startPoint, step.endPoint])
    ];
  }
  final List<NavigationStep> steps;
  final double totalDistance; 
  final int estimatedDuration;
  final int? destination; // ID da sala/estrutura de destino

  NavigationRoute({
    required this.steps,
    required this.totalDistance,
    required this.estimatedDuration,
    this.path,
    this.destination,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    return NavigationRoute(
      steps: (json['steps'] as List).map((step) => NavigationStep.fromJson(step)).toList(),
      totalDistance: json['totalDistance'],
      estimatedDuration: json['estimatedDuration'],
      destination: json['destination'],
    );
  }
}

class NavigationStep {
  final String instruction;
  final LatLng startPoint;
  final LatLng endPoint;
  final double distance; 
  final int duration; 
  final String maneuver; 
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

enum VoiceGuidanceLevel {
  off,
  basic,
  detailed,
}

class NavigationProgress {
  final int currentStepIndex;
  final double distanceToNextStep; 
  final double distanceToDestination; 
  final int estimatedTimeRemaining; 

  NavigationProgress({
    required this.currentStepIndex,
    required this.distanceToNextStep,
    required this.distanceToDestination,
    required this.estimatedTimeRemaining,
  });
}
