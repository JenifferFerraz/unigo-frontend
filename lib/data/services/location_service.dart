import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class LocationService extends GetxService {
  final RxBool isLocationEnabled = false.obs;
  final Rxn<Position> currentPosition = Rxn<Position>();

  Future<LocationService> init() async {
    try {
      // Verifica se o serviço de localização está habilitado
      isLocationEnabled.value = await Geolocator.isLocationServiceEnabled();
      
      if (isLocationEnabled.value) {
        // Verifica a permissão
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied) {
          // Obtém a posição atual
          currentPosition.value = await Geolocator.getCurrentPosition();
        }
      }
    } catch (e) {
      print('Erro ao inicializar serviço de localização: $e');
    }
    return this;
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

