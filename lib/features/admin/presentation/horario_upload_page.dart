import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/admin_upload_service.dart';
import 'admin_spreadsheet_upload.dart';
import 'package:intl/intl.dart';

class HorarioUploadPage extends StatefulWidget {
  const HorarioUploadPage({Key? key}) : super(key: key);

  @override
  State<HorarioUploadPage> createState() => _HorarioUploadPageState();
}

class _HorarioUploadPageState extends State<HorarioUploadPage> {
  List<Map<String, dynamic>> horarios = [];
  bool loading = true;

  // Listas para os dropdowns
  final List<String> daysOfWeek = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo'
  ];

  final List<String> shifts = ['Matutino', 'Vespertino', 'Noturno'];

  @override
  void initState() {
    super.initState();
    fetchHorarios();
  }

  Future<void> fetchHorarios() async {
    setState(() => loading = true);
    try {
      final service = AdminUploadService();
      final list = await service.getRecentSchedules();
      setState(() {
        horarios = list;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      Get.snackbar('Erro', 'Falha ao buscar horários: $e');
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
          'Tem certeza que deseja deletar o horário de "${item['subject'] ?? ''}"?\n\nEsta ação não pode ser desfeita.',
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
        await service.deleteSchedule(item['id'].toString());
        fetchHorarios();
        Get.snackbar(
          'Sucesso',
          'Horário deletado com sucesso!',
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
    
    print('=== SCHEDULE EDIT DEBUG ===');
    print('Raw item data: $item');
    print('==========================');
    
    final TextEditingController subjectController = TextEditingController(text: item['subject'] ?? '');
    final TextEditingController roomController = TextEditingController(text: item['room'] ?? '');
    final TextEditingController professorController = TextEditingController(text: item['professor'] ?? '');
    final TextEditingController timeController = TextEditingController(text: item['time'] ?? '');
    final TextEditingController semesterController = TextEditingController(
      text: item['semester']?.toString() ?? ''
    );
    
    String? selectedDay = item['dayOfWeek']?.toString();
    String? selectedShift = item['shift']?.toString();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 750),
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
                        child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Editar Horário',
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
                          controller: subjectController,
                          label: 'Disciplina',
                          icon: Icons.subject_rounded,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: professorController,
                          label: 'Professor',
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Dia da Semana',
                                icon: Icons.calendar_today_rounded,
                                value: selectedDay,
                                items: daysOfWeek,
                                onChanged: (v) {
                                  setDialogState(() {
                                    selectedDay = v;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: timeController,
                                label: 'Horário',
                                icon: Icons.access_time_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Turno',
                                icon: Icons.wb_sunny_rounded,
                                value: selectedShift,
                                items: shifts,
                                onChanged: (v) {
                                  setDialogState(() {
                                    selectedShift = v;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: semesterController,
                                label: 'Período',
                                icon: Icons.numbers_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: roomController,
                          label: 'Sala',
                          icon: Icons.meeting_room_rounded,
                        ),
                        
                        if (item['courseName'] != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.school_rounded, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Curso',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['courseName'].toString(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.blue[900],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                            await service.updateSchedule(
                              id: item['id'].toString(),
                              data: {
                                'subject': subjectController.text,
                                'professor': professorController.text,
                                'time': timeController.text,
                                'room': roomController.text,
                                'dayOfWeek': selectedDay,
                                'shift': selectedShift,
                                'semester': semesterController.text.isNotEmpty 
                                    ? int.tryParse(semesterController.text) ?? 1
                                    : 1,
                              },
                            );
                            Navigator.pop(context);
                            fetchHorarios();
                            Get.snackbar(
                              'Sucesso',
                              'Horário atualizado com sucesso!',
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final validValue = items.contains(value) ? value : null;
    
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
              items: items
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
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
            title: 'Horário de Aulas',
            instructions: 'Envie a planilha de horário. Aceito: .xlsx, .xls, .csv',
            uploadEndpoint: '/upload/schedule',
            templateType: 'schedule',
            tableData: horarios,
            tableColumns: const [
              TableColumn(label: 'ID', field: 'id'),
              TableColumn(label: 'Disciplina', field: 'subject'),
              TableColumn(label: 'Professor', field: 'professor'),
              TableColumn(label: 'Dia', field: 'dayOfWeek'),
              TableColumn(label: 'Horário', field: 'time'),
              TableColumn(label: 'Sala', field: 'room'),
              TableColumn(label: 'Turno', field: 'shift'),
              TableColumn(label: 'Período', field: 'semester'),
              TableColumn(label: 'Curso', field: 'courseName'),
            ],
            onEdit: handleEdit,
            onDelete: handleDelete,
            onUploadSuccess: fetchHorarios,
          );
  }
}