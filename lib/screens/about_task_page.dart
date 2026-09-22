import 'dart:ui';
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
    if (start != null && end != null) {
      final startTime = DateFormat('HH:mm').format(start);
      final endTime = DateFormat('HH:mm').format(end);
      return '$startTime - $endTime';
    } else {
      return 'Horário não definido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImagePath = context
        .watch<EnvironmentNotifier>()
        .backgroundImagePath;
    final theme = context.watch<EnvironmentNotifier>().currentTheme;

    return Scaffold(
      backgroundColor: AppConfig.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text('Detalhes da Tarefa', style: AppConfig().montserratTitle),
        leading: IconButton(
          icon: Icon(HugeIcons.strokeRoundedArrowLeft01, size: 34),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
              Text(
                task.description,
                style: AppConfig().montserratTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedCalendar04,
                    size: 18,
                    color: theme.colorScheme.primary,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'DETALHES DA TAREFA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          task.title,
                          style: AppConfig().quicksandTitle.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 12),
                        if (task.description.isNotEmpty) ...[
                          Text(
                            task.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Divider(color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: HugeIcons.strokeRoundedCalendar04,
                          iconColor: theme.colorScheme.primary,
                          label: 'Data',
                          value: DateFormat('dd/MM/yyyy').format(task.date),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: HugeIcons.strokeRoundedTime03,
                          iconColor: theme.colorScheme.primary,
                          label: 'Período',
                          value: _getHourPeriod(task.startTime, task.endTime),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Icons.check_circle_outline,
                          iconColor: task.completed ? Colors.green : Colors.white54,
                          label: 'Status',
                          value: task.completed ? 'Concluída' : 'Pendente',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Icons.priority_high_rounded,
                          iconColor: _getPriority(task.priority),
                          label: 'Prioridade',
                          value: _getPriorityText(task.priority),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Data: ${DateFormat('dd/MM/yyyy').format(task.date)}',
                    style: AppConfig().roboto,
                  ),
                ],
                ),
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
                    'Período: ${_getHourPeriod(task.startTime, task.endTime)}',
                    style: AppConfig().roboto,
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
