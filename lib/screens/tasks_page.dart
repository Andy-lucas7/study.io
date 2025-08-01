import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'new_task_page.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/settings_drawer.dart';
import '../styles.dart';
import '../notifiers/environment_notifier.dart';
import 'dart:ui';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> _tasks = [];
  bool _showTodayOnly = true;
  bool get wantkeepAlive => true;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isActive) {
        _loadTasks();
      }
    });
  }

  @override
  void dispose() {
    _isActive = false;
    super.dispose();
  }

  String _getPriorityText(int value) {
    switch (value) {
      case 0:
        return 'Baixa';
      case 1:
        return 'Média';
      case 2:
        return 'Alta';
      default:
        return 'Desconhecida';
    }
  }

  Future<void> _loadTasks() async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final startOfWeek = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(Duration(days: now.weekday - 1)));
    final endOfWeek = DateFormat(
      'yyyy-MM-dd',
    ).format(now.add(Duration(days: 7 - now.weekday)));

    final tasks = _showTodayOnly
        ? await DatabaseService.getTasksByDate(today)
        : await DatabaseService.getTasksByDateRange(startOfWeek, endOfWeek);

    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _toggleFilter() async {
    setState(() {
      _showTodayOnly = !_showTodayOnly;
    });
    await _loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    await DatabaseService.deleteTask(id);
    await _loadTasks();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    await DatabaseService.updateTaskCompletion(task.id!, !task.completed);
    await _loadTasks();
  }

  Future<void> _goToNewTaskPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewTaskPage()),
    );

    if (result == true) {
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Tarefas ${_showTodayOnly ? 'do dia' : 'da Semana'}',
          style: AppFonts().montserratTitle,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset('assets/icon/Icon_fill.png'),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showTodayOnly ? Icons.today : Icons.date_range),
            tooltip: _showTodayOnly ? 'Mostrar semana' : 'Mostrar hoje',
            onPressed: _toggleFilter,
          ),
        ],
      ),
      drawer: const SettingsDrawer(),
      body: _tasks.isEmpty
          ? const Center(child: Text('Nenhuma tarefa disponível.'))
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        shape: const CircleBorder(),
                        value: task.completed,
                        onChanged: (_) => _toggleTaskCompletion(task),
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.description),
                        Text('Data: ${task.date}'),
                        Text('Prioridade: ${_getPriorityText(task.priority)}'),
                        if (task.getStudyMinutes() > 0)
                          Text(
                            'Tempo estudado: ${_formatTime(task.getStudyMinutes())}',
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteTask(task.id!),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToNewTaskPage,
        tooltip: 'Criar nova tarefa',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0
          ? '${hours}h ${remainingMinutes}min'
          : '${hours}h';
    }
  }
}
