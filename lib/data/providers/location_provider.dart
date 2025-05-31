import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';
import '../models/navigation_model.dart';
import '../services/storage_service.dart';
import '../../core/config/env_service.dart';

class LocationProvider {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvService.apiBaseUrl,
    responseType: ResponseType.json,
  ));
  Future<List<Location>> getAllLocations({
    String? type,
    String? block,
    int? floor,
    String? search,
  }) async {
    try {
      final storageService = Get.find<StorageService>();
      final token = storageService.token.value;
      if (token == null) {
        throw 'No authentication token found';
      }
      
      final response = await _dio.get(
        '/locations',
        queryParameters: {
          if (type != null) 'type': type,
          if (block != null) 'block': block,
          if (floor != null) 'floor': floor,
          if (search != null) 'search': search,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((item) => Location.fromJson(item))
            .toList();
      }
      throw 'Failed to load locations';
    } catch (e) {
      throw 'Error fetching locations: $e';
    }
  }

  Future<List<String>> getBlocks() async {
    try {
      final response = await _dio.get('/locations/blocks');

      if (response.statusCode == 200) {
        return (response.data as List).map((item) => item.toString()).toList();
      }
      throw 'Failed to load blocks';
    } catch (e) {
      throw 'Error fetching blocks: $e';
    }
  }
  Future<List<Location>> searchLocations(String query) async {
    try {
      final storageService = Get.find<StorageService>();
      final token = storageService.token.value;
      if (token == null) {
        print('Error: No authentication token found');
        throw 'No authentication token found';
      }

      print('Searching locations with query: $query');
      final response = await _dio.get(
        '/locations/search',
        queryParameters: {'q': query},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('Search response status: ${response.statusCode}');
      print('Search response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((item) {
          try {
            return Location.fromJson(item);
          } catch (e) {
            print('Error parsing location: $e');
            print('Location data: $item');
            rethrow;
          }
        }).toList();
      }

      print('Search failed with status: ${response.statusCode}');
      throw 'Failed to search locations: ${response.statusCode}';
    } on DioException catch (e) {
      print('Dio error: ${e.type}');
      print('Dio response: ${e.response?.data}');
      print('Dio status code: ${e.response?.statusCode}');
      throw 'Error searching locations: ${e.message}';
    } catch (e) {
      print('Unexpected error: $e');
      throw 'Error searching locations: $e';
    }
  }
  Future<List<ClassNotification>> getUpcomingClasses() async {
    try {
      final storageService = Get.find<StorageService>();
      final token = storageService.token.value;
      if (token == null) {
        throw 'No authentication token found';
      }

      final response = await _dio.get(
        '/notifications/upcoming-classes',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((item) => ClassNotification.fromJson(item))
            .toList();
      }
      throw 'Failed to load upcoming classes';
    } catch (e) {
      throw 'Error fetching upcoming classes: $e';
    }
  }
  Future<NavigationRoute?> getNavigationRoute(LatLng start, LatLng end) async {
    try {
      final storageService = Get.find<StorageService>();
      final token = storageService.token.value;
      if (token == null) {
        throw 'No authentication token found';
      }

      final response = await _dio.get(
        '/navigation/route',
        queryParameters: {
          'startLat': start.latitude,
          'startLng': start.longitude,
          'endLat': end.latitude,
          'endLng': end.longitude,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return NavigationRoute.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error getting navigation route: $e');
      return null;
    }
  }
}
