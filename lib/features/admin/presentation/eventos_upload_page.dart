import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/admin_upload_service.dart';
import 'admin_spreadsheet_upload.dart';
import '../../events/data/event_api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class EventosUploadPage extends StatefulWidget {
  const EventosUploadPage({Key? key}) : super(key: key);

  @override
  State<EventosUploadPage> createState() => _EventosUploadPageState();
}

class _EventosUploadPageState extends State<EventosUploadPage> {
  List<Map<String, dynamic>> cursos = [];
  bool cursosLoading = false;
  List<Map<String, dynamic>> eventos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchEventos();
    fetchCursos();
  }

  Future<void> fetchCursos() async {
    setState(() => cursosLoading = true);
    try {
      final service = EventApiService();
      final list = await service.fetchCourses();
      setState(() {
        cursos = list;
        cursosLoading = false;
      });
    } catch (e) {
      setState(() => cursosLoading = false);
      Get.snackbar('Erro', 'Falha ao buscar cursos: $e');
    }
  }

  Future<void> fetchEventos() async {
    setState(() => loading = true);
    try {
      final service = AdminUploadService();
      final list = await service.getRecentEvents();
      setState(() {
        eventos = list;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      Get.snackbar('Erro', 'Falha ao buscar eventos: $e');
    }
  }

  Future<void> handleDelete(Map<String, dynamic> item) async {
    const appBlue = Color(0xFF3C3CC0);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_rounded, color: Colors.red[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Confirmar Exclusão', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          'Tem certeza que deseja deletar o evento "${item['title'] ?? ''}"?\n\nEsta ação não pode ser desfeita.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Deletar', style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = AdminUploadService();
        await service.deleteEvent(item['id'].toString());
        fetchEventos();
        Get.snackbar(
          'Sucesso',
          'Evento deletado com sucesso!',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
        );
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Falha ao deletar: $e',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }
    }
  }

  Future<void> handleEdit(Map<String, dynamic> item) async {
    const appBlue = Color(0xFF3C3CC0);
    
    print('=== INITIAL DEBUG ===');
    print('Raw item data: $item');
    print('Course value: ${item['course']}');
    print('Available courses: ${cursos.map((c) => c['name']).toList()}');
    print('====================');
    
    final TextEditingController titleController = TextEditingController(text: item['title'] ?? '');
    final bool hasType = item.containsKey('type') && item['type'] != null;
    final TextEditingController typeController = hasType ? TextEditingController(text: item['type'] ?? '') : TextEditingController();
    final TextEditingController descriptionController = TextEditingController(text: item['description'] ?? '');
    final TextEditingController locationController = TextEditingController(text: item['location'] ?? '');
    final TextEditingController linkController = TextEditingController(text: item['link'] ?? '');
    
    String? selectedCourse = item['course']?.toString();
    DateTime? startDate;
    DateTime? endDate;
    
    // Parse start date - usa o campo original, não o formatado
    try {
      if (item['startDate'] != null && item['startDate'].toString().isNotEmpty) {
        final dateStr = item['startDate'].toString();
        // Tenta parsear diferentes formatos
        if (dateStr.contains('T')) {
          // Formato ISO: 2025-01-03T00:00:00.000Z
          startDate = DateTime.parse(dateStr).toLocal();
        } else if (dateStr.contains('/')) {
          // Formato brasileiro: 03/01/2025
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            startDate = DateTime(
              int.parse(parts[2]), // ano
              int.parse(parts[1]), // mês
              int.parse(parts[0]), // dia
            );
          }
        }
        print('Parsed startDate: $startDate');
      }
    } catch (e) {
      print('Error parsing startDate: $e');
    }
    
    // Parse end date - usa o campo original, não o formatado
    try {
      if (item['endDate'] != null && item['endDate'].toString().isNotEmpty) {
        final dateStr = item['endDate'].toString();
        // Tenta parsear diferentes formatos
        if (dateStr.contains('T')) {
          // Formato ISO: 2026-02-03T00:00:00.000Z
          endDate = DateTime.parse(dateStr).toLocal();
        } else if (dateStr.contains('/')) {
          // Formato brasileiro: 03/02/2026
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            endDate = DateTime(
              int.parse(parts[2]), // ano
              int.parse(parts[1]), // mês
              int.parse(parts[0]), // dia
            );
          }
        }
        print('Parsed endDate: $endDate');
      }
    } catch (e) {
      print('Error parsing endDate: $e');
    }

    await showDialog(
      context: context,
      builder: (context) {
        // Debug: imprimir as datas no console
        print('=== EDIT DIALOG DEBUG ===');
        print('Item: ${item['title']}');
        print('StartDate from item: ${item['startDate']}');
        print('EndDate from item: ${item['endDate']}');
        print('Parsed startDate: $startDate');
        print('Parsed endDate: $endDate');
        print('========================');
        
        return StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: appBlue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Editar Evento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: titleController,
                          label: 'Título',
                          icon: Icons.title_rounded,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                context: context,
                                label: 'Data de Início',
                                icon: Icons.calendar_today_rounded,
                                selectedDate: startDate,
                                onDateSelected: (date) {
                                  setDialogState(() {
                                    startDate = date;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateField(
                                context: context,
                                label: 'Data de Término',
                                icon: Icons.event_rounded,
                                selectedDate: endDate,
                                onDateSelected: (date) {
                                  setDialogState(() {
                                    endDate = date;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (hasType) ...[
                          _buildTextField(
                            controller: typeController,
                            label: 'Tipo',
                            icon: Icons.category_rounded,
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        _buildTextField(
                          controller: locationController,
                          label: 'Local',
                          icon: Icons.location_on_rounded,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: linkController,
                          label: 'Link',
                          icon: Icons.link_rounded,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: descriptionController,
                          label: 'Descrição',
                          icon: Icons.description_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        
                        cursosLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildDropdownField(
                                label: 'Curso',
                                icon: Icons.school_rounded,
                                value: selectedCourse,
                                items: cursos,
                                onChanged: (v) {
                                  setDialogState(() {
                                    selectedCourse = v;
                                  });
                                },
                              ),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: () async {
                          final service = AdminUploadService();
                          try {
                            final Map<String, dynamic> data = {
                              'title': titleController.text,
                              'startDate': startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : '',
                              'endDate': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : '',
                              'description': descriptionController.text,
                              'location': locationController.text,
                              'link': linkController.text,
                              'course': selectedCourse,
                            };
                            if (hasType) {
                              data['type'] = typeController.text;
                            }
                            await service.updateEvent(
                              id: item['id'].toString(),
                              data: data,
                            );
                            Navigator.pop(context);
                            fetchEventos();
                            Get.snackbar(
                              'Sucesso',
                              'Evento atualizado com sucesso!',
                              backgroundColor: Colors.green[100],
                              colorText: Colors.green[900],
                            );
                          } catch (e) {
                            Get.snackbar(
                              'Erro',
                              'Falha ao atualizar: $e',
                              backgroundColor: Colors.red[100],
                              colorText: Colors.red[900],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF3C3CC0), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3C3CC0), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : 'Selecionar data',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                      color: selectedDate != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
  }) {
    // Remove duplicatas usando um Set baseado no nome do curso
    final uniqueItems = <String, Map<String, dynamic>>{};
    for (var item in items) {
      final courseName = item['name'].toString();
      // Mantém apenas o primeiro registro de cada curso (ou o mais recente)
      if (!uniqueItems.containsKey(courseName)) {
        uniqueItems[courseName] = item;
      }
    }
    
    final uniqueList = uniqueItems.values.toList();
    
    // Verifica se o valor existe na lista (agora sem duplicatas)
    final validValue = uniqueList.any((item) => item['name'].toString() == value) ? value : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3C3CC0), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: validValue,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
              items: uniqueList
                  .map((c) => DropdownMenuItem<String>(
                        value: c['name'].toString(),
                        child: Text(c['name'].toString()),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : AdminSpreadsheetUpload(
            title: 'Eventos',
            instructions: 'Envie a planilha de eventos. Aceito: .xlsx, .xls, .csv',
            uploadEndpoint: '/upload/events',
            templateType: 'events',
            tableData: eventos.map((e) {
              final newMap = Map<String, dynamic>.from(e);
              // Adiciona campos formatados para exibição na tabela
              // mas mantém os originais para edição
              if (e['startDate'] != null && e['startDate'].toString().isNotEmpty) {
                try {
                  final dt = DateTime.parse(e['startDate']);
                  newMap['startDateFormatted'] = DateFormat('dd/MM/yyyy').format(dt);
                } catch (_) {
                  newMap['startDateFormatted'] = e['startDate'];
                }
              }
              if (e['endDate'] != null && e['endDate'].toString().isNotEmpty) {
                try {
                  final dt = DateTime.parse(e['endDate']);
                  newMap['endDateFormatted'] = DateFormat('dd/MM/yyyy').format(dt);
                } catch (_) {
                  newMap['endDateFormatted'] = e['endDate'];
                }
              }
              return newMap;
            }).toList(),
            tableColumns: const [
              TableColumn(label: 'ID', field: 'id'),
              TableColumn(label: 'Título', field: 'title'),
              TableColumn(label: 'Descrição', field: 'description'),
              TableColumn(label: 'Início', field: 'startDateFormatted'),
              TableColumn(label: 'Fim', field: 'endDateFormatted'),
              TableColumn(label: 'Local', field: 'location'),
              TableColumn(label: 'Link', field: 'link'),
            ],
            onEdit: handleEdit,
            onDelete: handleDelete,
          );
  }
}