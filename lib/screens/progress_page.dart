import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_io/core/app_config.dart';
import '../models/task.dart';
import '../models/metric.dart';
import '../services/database_service.dart';
import '../widgets/settings_drawer.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  // Tarefas
  double _progressPercent = 0.0;
  int _tasksCompleted = 0;
  int _totalTasks = 0;

  // Métricas de estudo
  int _totalStudyMinutes = 0;
  int _totalPauses = 0;

  // Por períodos
  int _todayStudyMinutes = 0;
  int _todayPauses = 0;
  int _weekStudyMinutes = 0;
  int _weekPauses = 0;

  // Gráfico
  List<int> _dailyStudyMinutes = List.filled(7, 0);
  List<int> _dailyPauses = List.filled(7, 0);
  final List<String> _weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();

    // Pega todas tarefas (para progresso)
    final List<Task> allTasks = await DatabaseService.getTasks();

    // Pega todas métricas do Firestore
    final metricsSnapshot = await FirebaseFirestore.instance.collection('metrics').get();
    final List<Metric> allMetrics = metricsSnapshot.docs.map((doc) => Metric.fromDoc(doc)).toList();

    // --- Cálculos para tarefas ---
    final completedTasks = allTasks.where((t) => t.completed).toList();
    final totalTasks = allTasks.length;

    // --- Cálculos para métricas ---

    // Função auxiliar para checar se a string da data bate com a data desejada
    bool isSameDateString(String a, DateTime b) {
      return a == DateFormat('yyyy-MM-dd').format(b);
    }

    // Define intervalo semana atual (de domingo a sábado)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(Duration(days: 7));

    // Filtra métricas do período de interesse
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final weekDates = List.generate(7, (i) => DateFormat('yyyy-MM-dd').format(startOfWeek.add(Duration(days: i))));

    // Métricas totais (somatório geral)
    int totalStudy = 0;
    int totalPauses = 0;

    // Métricas hoje e semana
    int todayStudy = 0;
    int todayPauses = 0;
    int weekStudy = 0;
    int weekPauses = 0;

    // Para gráfico diário
    List<int> dailyStudy = List.filled(7, 0);
    List<int> dailyPauses = List.filled(7, 0);

    for (final metric in allMetrics) {
      totalStudy += metric.studyMinutes;
      totalPauses += metric.pauses;

      if (metric.date == todayStr) {
        todayStudy += metric.studyMinutes;
        todayPauses += metric.pauses;
      }

      // Está dentro da semana atual?
      if (weekDates.contains(metric.date)) {
        weekStudy += metric.studyMinutes;
        weekPauses += metric.pauses;

        // Preenche diário
        final dayIndex = weekDates.indexOf(metric.date);
        if (dayIndex != -1) {
          dailyStudy[dayIndex] += metric.studyMinutes;
          dailyPauses[dayIndex] += metric.pauses;
        }
      }
    }

    setState(() {
      // Tarefas
      _tasksCompleted = completedTasks.length;
      _totalTasks = totalTasks;
      _progressPercent = totalTasks == 0 ? 0 : _tasksCompleted / totalTasks;

      // Métricas gerais
      _totalStudyMinutes = totalStudy;
      _totalPauses = totalPauses;

      // Métricas períodos
      _todayStudyMinutes = todayStudy;
      _todayPauses = todayPauses;
      _weekStudyMinutes = weekStudy;
      _weekPauses = weekPauses;

      // Gráfico
      _dailyStudyMinutes = dailyStudy;
      _dailyPauses = dailyPauses;
    });
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h $m min' : '${h}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Progresso', style: AppConfig().montserratTitle),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset('assets/icon/Icon_fill.png'),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SettingsDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo do progresso', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Barra de progresso tarefas
            Stack(
              alignment: Alignment.center,
              children: [
                LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(8),
                  value: _progressPercent,
                  minHeight: 24,
                  backgroundColor: theme.colorScheme.primary.withAlpha(50),
                  color: theme.colorScheme.primary,
                ),
                Text('${(_progressPercent * 100).toStringAsFixed(0)}% Concluídos',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 30),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statCard('Tarefas', '$_tasksCompleted / $_totalTasks', Icons.check_circle, theme),
                _statCard('Tempo Estudo (Total)', _formatTime(_totalStudyMinutes), Icons.timer, theme),
                _statCard('Pausas (Total)', '$_totalPauses', Icons.pause_circle_filled, theme),
                _statCard('Hoje - Estudo', _formatTime(_todayStudyMinutes), Icons.today, theme),
                _statCard('Hoje - Pausas', '$_todayPauses', Icons.pause_circle, theme),
                _statCard('Semana - Estudo', _formatTime(_weekStudyMinutes), Icons.date_range, theme),
                _statCard('Semana - Pausas', '$_weekPauses', Icons.schedule, theme),
              ],
            ),

            const SizedBox(height: 24),

            if (_totalTasks > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Você já concluiu $_tasksCompleted ${_tasksCompleted > 1 ? 'tarefas' : 'tarefa'} no total!',
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            const Text('Tempo de estudo e pausas por dia da semana',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),

            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.tile,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildStudyPauseBarChart(theme),
            ),

            const SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, ThemeData theme) {
    return Card(
      color: AppConfig.tile,
      elevation: 2,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.onPrimary),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyPauseBarChart(ThemeData theme) {
    final maxValue = [
      ..._dailyStudyMinutes,
      ..._dailyPauses,
    ].reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final studyHeight = (_dailyStudyMinutes[i] / maxValue) * 140;
        final pauseHeight = (_dailyPauses[i] / maxValue) * 140;
        final isToday = DateTime.now().weekday % 7 == i;
        // Mover a lógica visual para um widget separado
        Widget _buildStudyPauseBar(ThemeData theme, int studyMinutes, int pauses, String day, bool isToday, double maxValue) {
          final studyHeight = (studyMinutes / maxValue) * 140;
          final pauseHeight = (pauses / maxValue) * 140;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (studyMinutes > 0)
                Text(
                  _formatTime(studyMinutes),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              if (pauses > 0)
                Text(
                  '$pauses pausas',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                ),
              const SizedBox(height: 4),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 30,
                    height: pauseHeight.clamp(4.0, 140.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: studyHeight.clamp(4.0, 140.0),
                    decoration: BoxDecoration(
                      color: isToday ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday ? Border.all(color: theme.colorScheme.secondary, width: 2) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ],
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_dailyStudyMinutes[i] > 0)
              Text(
                _formatTime(_dailyStudyMinutes[i]),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            if (_dailyPauses[i] > 0)
              Text(
                '${_dailyPauses[i]} pausas',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
              ),
            const SizedBox(height: 4),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 30,
                  height: pauseHeight.clamp(4.0, 140.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  width: 30,
                  height: studyHeight.clamp(4.0, 140.0),
                  decoration: BoxDecoration(
                    color: isToday ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: theme.colorScheme.secondary, width: 2)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _weekDays[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        );
      }),
    );
  }
}
