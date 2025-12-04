import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/admin_upload_service.dart';
import 'admin_spreadsheet_upload.dart';

class ProvasUploadPage extends StatefulWidget {
  const ProvasUploadPage({Key? key}) : super(key: key);

  @override
  State<ProvasUploadPage> createState() => _ProvasUploadPageState();
}

class _ProvasUploadPageState extends State<ProvasUploadPage> {
  List<Map<String, dynamic>> provas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProvas();
  }

  Future<void> fetchProvas() async {
    setState(() => loading = true);
    try {
      final service = AdminUploadService();
      final list = await service.getRecentExams();
      setState(() {
        provas = list;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      Get.snackbar('Erro', 'Falha ao buscar provas: $e');
    }
  }

  Future<void> handleDelete(Map<String, dynamic> item) async {
    try {
      final service = AdminUploadService();
      await service.deleteExam(item['id'].toString());
      fetchProvas();
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao deletar: $e');
    }
  }

  Future<void> handleEdit(Map<String, dynamic> item) async {
    final TextEditingController titleController = TextEditingController(text: item['title'] ?? '');
    final TextEditingController dateController = TextEditingController(text: item['date'] ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Prova'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Data')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = AdminUploadService();
              await service.updateExam(
                id: item['id'].toString(),
                data: {
                  'title': titleController.text,
                  'date': dateController.text,
                },
              );
              Navigator.pop(context);
              fetchProvas();
            },
            child: const Text('Salvar'),
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
            title: 'Provas',
            instructions: 'Envie a planilha de provas. Aceito: .xlsx, .xls, .csv',
            uploadEndpoint: '/upload/exams',
            templateType: 'exams',
            tableData: provas,
            tableColumns: const [
              TableColumn(label: 'ID', field: 'id'),
              TableColumn(label: 'Título', field: 'title'),
              TableColumn(label: 'Data', field: 'date'),
              TableColumn(label: 'Tipo', field: 'type'),
              TableColumn(label: 'Descrição', field: 'description'),
            ],
            onEdit: handleEdit,
            onDelete: handleDelete,
          );
  }
}