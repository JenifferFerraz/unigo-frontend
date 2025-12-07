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
          'Tem certeza que deseja deletar a prova "${item['subject'] ?? ''}"?\n\nEsta ação não pode ser desfeita.',
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
        await service.deleteExam(item['id'].toString());
        fetchProvas();
        Get.snackbar(
          'Sucesso',
          'Prova deletada com sucesso!',
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
    final TextEditingController subjectController = TextEditingController(text: item['subject'] ?? '');
    final TextEditingController dateController = TextEditingController(text: item['date'] ?? '');
    final TextEditingController timeController = TextEditingController(text: item['time'] ?? '');
    final TextEditingController gradeController = TextEditingController(text: item['grade'] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Prova'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Matéria'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Data (dd/mm/yyyy)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Horário'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(labelText: 'Período'),
              ),
            ],
          ),
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
                  'subject': subjectController.text,
                  'date': dateController.text,
                  'time': timeController.text,
                  'grade': gradeController.text,
                },
              );
              Navigator.pop(context);
              fetchProvas();
              Get.snackbar(
                'Sucesso',
                'Prova atualizada!',
                backgroundColor: Colors.green[100],
                colorText: Colors.green[900],
              );
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
              TableColumn(label: 'Matéria', field: 'subject'),
              TableColumn(label: 'Data', field: 'date'),
              TableColumn(label: 'Dia', field: 'day'),
              TableColumn(label: 'Horário', field: 'time'),
              TableColumn(label: 'Período', field: 'grade'),
              TableColumn(label: 'Turno', field: 'shift'),
              TableColumn(label: 'Ciclo', field: 'cycle'),
            ],
            onEdit: handleEdit,
            onDelete: handleDelete,
          );
  }
}