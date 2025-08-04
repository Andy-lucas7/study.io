import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../core/app_config.dart';
import '../widgets/settings_drawer.dart';
import 'package:hugeicons/hugeicons.dart';

class AboutTaskPage extends StatelessWidget {
  final Task task;

  const AboutTaskPage({super.key, required this.task});

  Color _getPriority(int value) {
    switch (value) {
      case 0:
        return Colors.white;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<EnvironmentNotifier>().currentTheme;

    return Scaffold(
      backgroundColor: AppConfig.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text('Detalhes da Tarefa', style: AppConfig().montserratTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(HugeIcons.strokeRoundedArrowLeft01, size: 34,),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              task.title,
              style: AppConfig().quicksandTitle.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(task.description, style: AppConfig().roboto),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prazo: ${task.date.isNotEmpty ? task.date : 'Sem prazo'}',
                  style: AppConfig().roboto,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: task.completed
                      ? Colors.green
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  task.completed ? 'Concluída' : 'Pendente',
                  style: AppConfig().roboto,
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.priority_high_rounded,
                  size: 18,
                  color: _getPriority(task.priority),
                ),
                const SizedBox(width: 8),
                Text(
                  'Prioridade: ${_getPriorityText(task.priority)}',
                  style: AppConfig().roboto,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
