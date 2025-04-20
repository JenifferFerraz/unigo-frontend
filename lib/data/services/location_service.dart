import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class LocationService extends GetxService {
  final RxBool isLocationEnabled = false.obs;
  final Rxn<Position> currentPosition = Rxn<Position>();

  Future<LocationService> init() async {
    try {
      isLocationEnabled.value = await Geolocator.isLocationServiceEnabled();
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
}

