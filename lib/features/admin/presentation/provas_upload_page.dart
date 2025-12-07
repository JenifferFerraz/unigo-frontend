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
    const appBlue = Color(0xFF3C3CC0);
    
    final TextEditingController subjectController = TextEditingController(text: item['subject'] ?? '');
    final TextEditingController dateController = TextEditingController(text: item['date'] ?? '');
    final TextEditingController timeController = TextEditingController(text: item['time'] ?? '');
    final TextEditingController gradeController = TextEditingController(text: item['grade'] ?? '');
    final TextEditingController dayController = TextEditingController(text: item['day'] ?? '');
    final TextEditingController shiftController = TextEditingController(text: item['shift'] ?? '');
    
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
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Editar Prova',
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
                        controller: subjectController,
                        label: 'Matéria',
                        icon: Icons.subject_rounded,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: dateController,
                              label: 'Data',
                              icon: Icons.calendar_today_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: dayController,
                              label: 'Dia da Semana',
                              icon: Icons.event_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: timeController,
                              label: 'Horário',
                              icon: Icons.access_time_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: gradeController,
                              label: 'Período',
                              icon: Icons.school_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: shiftController,
                        label: 'Turno',
                        icon: Icons.wb_sunny_rounded,
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
                        try {
                          await service.updateExam(
                            id: item['id'].toString(),
                            data: {
                              'subject': subjectController.text,
                              'date': dateController.text,
                              'day': dayController.text,
                              'time': timeController.text,
                              'grade': gradeController.text,
                              'shift': shiftController.text,
                            },
                          );
                          Navigator.pop(context);
                          fetchProvas();
                          Get.snackbar(
                            'Sucesso',
                            'Prova atualizada com sucesso!',
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
              TableColumn(label: 'Curso ID', field: 'courseId'),
            ],
            onEdit: handleEdit,
            onDelete: handleDelete,
            onUploadSuccess: fetchProvas,
          );
  }
}