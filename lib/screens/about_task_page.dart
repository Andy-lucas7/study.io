import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../core/app_config.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

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

  String _getHourPeriod(DateTime? start, DateTime? end) {
    if (task.startTime != null && task.endTime != null) {
      final startTime = DateFormat('H:mm a').format(task.startTime!);
      final endTime = DateFormat('H:mm a').format(task.endTime!);
      return '$startTime - $endTime';
    } else {
      return 'Horário não definido';
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
            icon: Icon(HugeIcons.strokeRoundedArrowLeft01, size: 34),
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
              style: AppConfig().quicksandTitle.copyWith(fontSize: 34),
            ),
            const SizedBox(height: 12),
            Text(task.description, style: AppConfig().montserratTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedCalendar04,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data: ${DateFormat('dd/MM/yyyy').format(task.date)}',
                  style: AppConfig().roboto,
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedTime03,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Periodo: ${_getHourPeriod(task.startTime, task.endTime)}',
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
