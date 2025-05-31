import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../providers/location_provider.dart';
import '../models/location_model.dart';
import '../models/navigation_model.dart';

class LocationService extends GetxService {
  final RxBool isLocationEnabled = false.obs;
  final Rxn<Position> currentPosition = Rxn<Position>();
  final RxList<Location> locations = RxList<Location>();
  final RxList<String> blocks = RxList<String>();
  final RxList<ClassNotification> upcomingClasses = RxList<ClassNotification>();
  
  final Rxn<NavigationRoute> activeRoute = Rxn<NavigationRoute>();
  final Rxn<NavigationProgress> navigationProgress = Rxn<NavigationProgress>();
  final RxBool isNavigating = false.obs;

  final LocationProvider _locationProvider = LocationProvider();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  Timer? _locationUpdateTimer;

  Future<LocationService> init() async {
    try {
      isLocationEnabled.value = await Geolocator.isLocationServiceEnabled();
      await getBlocks();
    } catch (e) {
      print('Erro ao inicializar serviço de localização: $e');
    }
    return this;
  }

  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied) {
        currentPosition.value = await Geolocator.getCurrentPosition();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao solicitar permissão de localização: $e');
      return false;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      currentPosition.value = position;
      return position;
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  Future<void> fetchLocations({String? type, String? block, int? floor, String? search}) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final result = await _locationProvider.getAllLocations(
        type: type,
        block: block,
        floor: floor,
        search: search
      );
      
      locations.value = result;
    } catch (e) {
      error.value = 'Erro ao carregar localizações: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getBlocks() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final result = await _locationProvider.getBlocks();
      blocks.value = result;
    } catch (e) {
      error.value = 'Erro ao carregar blocos: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Location>> searchLocations(String query) async {
    try {
      if (query.isEmpty) return [];
      
      isLoading.value = true;
      error.value = '';
      
      final result = await _locationProvider.searchLocations(query);
      return result;
    } catch (e) {
      error.value = 'Erro na busca de localizações: $e';
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUpcomingClasses() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final result = await _locationProvider.getUpcomingClasses();
      upcomingClasses.value = result;
    } catch (e) {
      error.value = 'Erro ao carregar próximas aulas: $e';
    } finally {
      isLoading.value = false;
    }
  }

  double calculateDistance(double destLat, double destLng) {
    if (currentPosition.value == null) return 0;
    
    return Geolocator.distanceBetween(
      currentPosition.value!.latitude,
      currentPosition.value!.longitude,
      destLat,
      destLng
    );
  }
  
  Future<bool> startNavigation(Location destination) async {
    try {
      if (currentPosition.value == null) {
        await requestLocationPermission();
      }
      
      if (currentPosition.value == null || 
          destination.latitude == null || 
          destination.longitude == null) {
        error.value = 'Não foi possível obter localização atual ou do destino';
        return false;
      }
      
      isLoading.value = true;
      
      final route = await _locationProvider.getNavigationRoute(
        LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
        LatLng(destination.latitude!, destination.longitude!)
      );
      
      if (route == null) {
        error.value = 'Não foi possível calcular a rota para o destino';
        return false;
      }
      
      activeRoute.value = route;
      navigationProgress.value = NavigationProgress(
        currentStepIndex: 0,
        distanceToNextStep: route.steps[0].distance,
        distanceToDestination: route.totalDistance,
        estimatedTimeRemaining: route.estimatedDuration
      );
      
      _startLocationTracking();
      
      isNavigating.value = true;
      return true;
    } catch (e) {
      error.value = 'Erro ao iniciar navegação: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  void stopNavigation() {
    isNavigating.value = false;
    activeRoute.value = null;
    navigationProgress.value = null;
    _stopLocationTracking();
  }
  
  void _startLocationTracking() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!isNavigating.value) {
        timer.cancel();
        return;
      }
      
      final position = await getCurrentLocation();
      if (position == null || activeRoute.value == null || navigationProgress.value == null) return;
      
      _updateNavigationProgress(position);
    });
  }
  
  void _stopLocationTracking() {
    _locationUpdateTimer?.cancel();
  }
  
  void _updateNavigationProgress(Position position) {
    if (activeRoute.value == null || navigationProgress.value == null) return;
    
    final route = activeRoute.value!;
    final currentStep = route.steps[navigationProgress.value!.currentStepIndex];
    
    final distanceToStepEnd = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.endPoint.latitude,
      currentStep.endPoint.longitude
    );
    
    final distanceToDestination = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      route.steps.last.endPoint.latitude,
      route.steps.last.endPoint.longitude
    );
    
    navigationProgress.value = NavigationProgress(
      currentStepIndex: navigationProgress.value!.currentStepIndex,
      distanceToNextStep: distanceToStepEnd,
      distanceToDestination: distanceToDestination,
      estimatedTimeRemaining: (distanceToDestination / route.totalDistance * route.estimatedDuration).round()
    );
    

    if (distanceToStepEnd < 10) { 
      _advanceToNextStep();
    }
  }
  
  void _advanceToNextStep() {
    if (activeRoute.value == null || navigationProgress.value == null) return;
    
    final nextStepIndex = navigationProgress.value!.currentStepIndex + 1;
    
    if (nextStepIndex >= activeRoute.value!.steps.length) {
      stopNavigation();
      return;
    }
    
    final nextStep = activeRoute.value!.steps[nextStepIndex];
    navigationProgress.value = NavigationProgress(
      currentStepIndex: nextStepIndex,
      distanceToNextStep: nextStep.distance,
      distanceToDestination: navigationProgress.value!.distanceToDestination,
      estimatedTimeRemaining: navigationProgress.value!.estimatedTimeRemaining
    );
  }

  @override
  void onClose() {
    _stopLocationTracking();
    super.onClose();
  }
}

