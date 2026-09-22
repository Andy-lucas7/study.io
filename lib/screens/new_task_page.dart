import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../core/app_config.dart';

class NewTaskPage extends StatefulWidget {
  const NewTaskPage({super.key});

  @override
  State<NewTaskPage> createState() => _NewTaskPageState();
}

class _NewTaskPageState extends State<NewTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _priority = 2; // padrão: Média

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  DateTime? _combineDateWithTime(DateTime date, TimeOfDay? time) {
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final startDateTime = _combineDateWithTime(_selectedDate, _startTime);
      final endDateTime = _combineDateWithTime(_selectedDate, _endTime);

      final newTask = Task(
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        priority: _priority,
        startTime: startDateTime,
        endTime: endDateTime,
      );

      await DatabaseService.insertTask(newTask);
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImagePath = context
        .watch<EnvironmentNotifier>()
        .backgroundImagePath;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: backgroundImagePath.isNotEmpty
                ? Image.asset(backgroundImagePath, fit: BoxFit.cover)
                : Container(color: AppConfig.background),
          ),
          // Glass Box
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'NOVA TAREFA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildTextField(
                            controller: _titleController,
                            label: 'Título',
                            icon: HugeIcons.strokeRoundedTask01,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Informe o título'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Descrição',
                            icon: HugeIcons.strokeRoundedTextFont,
                            maxLines: 3,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Informe a descrição'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          _buildDateTimeField(
                            title: 'Data',
                            value: DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedDate),
                            icon: HugeIcons.strokeRoundedCalendar01,
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateTimeField(
                                  title: 'Início',
                                  value: _startTime != null
                                      ? _startTime!.format(context)
                                      : '--:--',
                                  icon: HugeIcons.strokeRoundedTime01,
                                  onTap: _selectStartTime,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateTimeField(
                                  title: 'Fim',
                                  value: _endTime != null
                                      ? _endTime!.format(context)
                                      : '--:--',
                                  icon: HugeIcons.strokeRoundedTime04,
                                  onTap: _selectEndTime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<int>(
                            value: _priority,
                            dropdownColor: Colors.black87,
                            style: const TextStyle(color: Colors.white),
                            iconEnabledColor: Colors.white70,
                            decoration: InputDecoration(
                              labelText: 'Prioridade',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: Icon(
                                HugeIcons.strokeRoundedStar,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Baixa')),
                              DropdownMenuItem(value: 1, child: Text('Média')),
                              DropdownMenuItem(value: 2, child: Text('Alta')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _priority = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _saveTask,
                              child: const Text(
                                'SALVAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateTimeField({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
