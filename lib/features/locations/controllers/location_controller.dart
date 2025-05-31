import 'package:get/get.dart';
import '../../../data/services/location_service.dart';
import '../../../data/models/location_model.dart';

class LocationController extends GetxController {
  final LocationService _locationService = Get.find<LocationService>();
  
  RxBool get isLoading => _locationService.isLoading;
  RxString get error => _locationService.error;
  RxList<Location> get locations => _locationService.locations;
  RxList<String> get blocks => _locationService.blocks;
  RxList<ClassNotification> get upcomingClasses => _locationService.upcomingClasses;
  
  final RxString selectedBlock = ''.obs;
  final RxInt selectedFloor = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedType = ''.obs;

  // Filtros disponíveis
  final List<String> locationTypes = ['classroom', 'laboratory', 'library', 'block', 'building', 'cafeteria', 'auditorium', 'administrative', 'other'];
  
  @override
  void onInit() {
    super.onInit();
    fetchLocations();
    loadUpcomingClasses();
  }

  // Carrega localizações com filtros aplicados
  Future<void> fetchLocations() async {
    await _locationService.fetchLocations(
      type: selectedType.value.isNotEmpty ? selectedType.value : null,
      block: selectedBlock.value.isNotEmpty ? selectedBlock.value : null,
      floor: selectedFloor.value > 0 ? selectedFloor.value : null,
      search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
    );
  }

  // Carrega aulas próximas
  Future<void> loadUpcomingClasses() async {
    await _locationService.loadUpcomingClasses();
  }

  // Aplicar filtros
  Future<void> applyFilters({String? type, String? block, int? floor, String? search}) async {
    if (type != null) selectedType.value = type;
    if (block != null) selectedBlock.value = block;
    if (floor != null) selectedFloor.value = floor;
    if (search != null) searchQuery.value = search;

    await fetchLocations();
  }

  // Limpar todos os filtros
  Future<void> clearFilters() async {
    selectedType.value = '';
    selectedBlock.value = '';
    selectedFloor.value = 0;
    searchQuery.value = '';

    await fetchLocations();
  }

  // Buscar localizações
  Future<List<Location>> searchLocations(String query) async {
    searchQuery.value = query;
    return await _locationService.searchLocations(query);
  }

  // Solicitar permissão de localização
  Future<bool> requestLocationPermission() async {
    return await _locationService.requestLocationPermission();
  }
}
