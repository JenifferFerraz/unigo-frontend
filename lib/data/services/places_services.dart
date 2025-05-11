import 'package:get/get.dart';

class PlacesServices extends GetxService {
  final RxList<String> searchHistory = <String>[].obs;
  final RxList<String> suggestions = <String>[].obs;
  // Lista estática de locais disponíveis para pesquisa
  final List<String> locations = [
    'Bloco I, Sala 203',
    'Auditório Bloco F',
    'Bloco H, Sala 101',
    'Bloco A, Sala 108',
    'Secretaria Geral',

  ];
 /// Busca locais que correspondam à consulta fornecida
  /// Retorna lista vazia se a consulta estiver vazia
  Future<List<String>> search(String query) async {
    if (query.isEmpty) return [];
    
    return locations.where((location) =>
      location.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Adiciona uma consulta ao histórico
  /// Mantém apenas as 10 pesquisas mais recentes
  void addToHistory(String query) {
    if (!searchHistory.contains(query)) {
      searchHistory.insert(0, query);
      if (searchHistory.length > 10) {
        searchHistory.removeLast();
      }
    }
  }
  /// Limpa todo o histórico de pesquisas
  void clearHistory() {
    searchHistory.clear();
  }
}