import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/admin_upload_service.dart';
import 'admin_spreadsheet_upload.dart';
import 'package:intl/intl.dart';

class CalendarioUploadPage extends StatefulWidget {
  const CalendarioUploadPage({Key? key}) : super(key: key);

  @override
  State<CalendarioUploadPage> createState() => _CalendarioUploadPageState();
}

class _CalendarioUploadPageState extends State<CalendarioUploadPage> {
  List<Map<String, dynamic>> calendario = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCalendario();
  }

  Future<void> fetchCalendario() async {
    setState(() => loading = true);
    try {
      final service = AdminUploadService();
      final list = await service.getRecentCalendars();
      setState(() {
        calendario = list;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      Get.snackbar('Erro', 'Falha ao buscar calendário: $e');
    }
  }

  Future<void> handleDelete(Map<String, dynamic> item) async {
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
          'Tem certeza que deseja deletar o item "${item['title'] ?? ''}"?\n\nEsta ação não pode ser desfeita.',
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
        await service.deleteCalendar(item['id'].toString());
        fetchCalendario();
        Get.snackbar(
          'Sucesso',
          'Item deletado com sucesso!',
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
    final TextEditingController titleController = TextEditingController(text: item['title'] ?? '');
    final TextEditingController typeController = TextEditingController(text: item['type'] ?? '');
    final TextEditingController courseController = TextEditingController(text: item['course'] ?? '');
    final TextEditingController descriptionController = TextEditingController(text: item['description'] ?? '');
    
    DateTime? selectedDate;
    try {
      if (item['date'] != null && item['date'].toString().isNotEmpty) {
        selectedDate = DateFormat('yyyy-MM-dd').parse(item['date'], true);
      }
    } catch (_) {}

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Editar Item do Calendário',
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
                      _buildDateField(
                        context: context,
                        label: 'Data',
                        icon: Icons.calendar_today_rounded,
                        selectedDate: selectedDate,
                        onDateSelected: (date) => selectedDate = date,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: typeController,
                        label: 'Tipo',
                        icon: Icons.category_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: courseController,
                        label: 'Curso',
                        icon: Icons.school_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: descriptionController,
                        label: 'Descrição',
                        icon: Icons.description_rounded,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
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
                        await service.updateCalendar(
                          id: item['id'].toString(),
                          data: {
                            'title': titleController.text,
                            'date': selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : '',
                            'type': typeController.text,
                            'course': courseController.text,
                            'description': descriptionController.text,
                          },
                        );
                        Navigator.pop(context);
                        fetchCalendario();
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
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF3C3CC0),
                ),
              ),
              child: child!,
            );
          },
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

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : AdminSpreadsheetUpload(
            title: 'Calendário',
            instructions: 'Envie a planilha de calendário. Aceito: .xlsx, .xls, .csv',
            uploadEndpoint: '/upload/calendar',
            templateType: 'calendar',
            tableData: calendario,
            tableColumns: const [
              TableColumn(label: 'ID', field: 'id'),
              TableColumn(label: 'Título', field: 'title'),
              TableColumn(label: 'Data', field: 'date'),
              TableColumn(label: 'Tipo', field: 'type'),
              TableColumn(label: 'Curso', field: 'course'),
              TableColumn(label: 'Descrição', field: 'description'),
            ],
            onEdit: handleEdit,
            onDelete: handleDelete,
            onUploadSuccess: fetchCalendario,
          );
  }
}