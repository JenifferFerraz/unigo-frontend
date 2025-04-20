import 'package:get/get.dart';

class PlacesServices extends GetxService {
  final RxList<String> searchHistory = <String>[].obs;
  final RxList<String> suggestions = <String>[].obs;

  final List<String> locations = [
    'Bloco I, Sala 203',
    'Auditório Bloco F',
    'Bloco H, Sala 101',
    'Bloco A, Sala 108',
    'Secretaria Geral',

  ];

  Future<List<String>> search(String query) async {
    if (query.isEmpty) return [];
    
    return locations.where((location) =>
      location.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  void addToHistory(String query) {
    if (!searchHistory.contains(query)) {
      searchHistory.insert(0, query);
      if (searchHistory.length > 10) {
        searchHistory.removeLast();
      }
    }
  }

  void clearHistory() {
    searchHistory.clear();
  }
}