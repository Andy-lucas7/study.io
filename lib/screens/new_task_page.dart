import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class NewTaskPage extends StatefulWidget {
  const NewTaskPage({super.key});

  @override
  State<NewTaskPage> createState() => _NewTaskPageState();
}

class _NewTaskPageState extends State<NewTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
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

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final newTask = Task(
        title: _titleController.text,
        description: _descriptionController.text,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        priority: _priority,
      );

      await DatabaseService.insertTask(newTask);
      Navigator.pop(context, true); // Retorna pra indicar sucesso
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Tarefa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o título' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Baixa')),
                  DropdownMenuItem(value: 2, child: Text('Média')),
                  DropdownMenuItem(value: 3, child: Text('Alta')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTask,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
