import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../notifiers/theme_notifier.dart';
import '../services/database_service.dart';
import '../models/task.dart';
import '../widgets/settings_drawer.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  double _progressPercent = 0.0;
  int _totalMinutesStudied = 0;
  int _tasksCompleted = 0;
  int _totalTasks = 0;
  int _todayMinutes = 0;
  int _weekMinutes = 0;
  List<int> _dailyMinutes = List.filled(7, 0);
  final List<String> _weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final List<Task> allTasks = await DatabaseService.getTasks();
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final weekDates = List.generate(
      7,
      (i) => DateFormat('yyyy-MM-dd').format(startOfWeek.add(Duration(days: i))),
    );

    final completedTasks = allTasks.where((task) => task.completed).toList();
    final totalMinutes = completedTasks.fold<int>(
      0,
      (sum, task) => sum + task.getStudyMinutes(),
    );
    final todayTasks = allTasks.where((task) => task.date == today).toList();
    final todayMinutes = todayTasks.fold<int>(
      0,
      (sum, task) => sum + (task.completed ? task.getStudyMinutes() : 0),
    );
    final weekTasks = allTasks.where((task) {
      final taskDate = DateTime.parse(task.date);
      return taskDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          taskDate.isBefore(startOfWeek.add(const Duration(days: 7)));
    }).toList();
    final weekMinutes = weekTasks.fold<int>(
      0,
      (sum, task) => sum + (task.completed ? task.getStudyMinutes() : 0),
    );

    final List<int> dailyMinutes = List.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final dayTasks = allTasks.where((task) => task.date == weekDates[i]).toList();
      dailyMinutes[i] = dayTasks.fold<int>(
        0,
        (sum, task) => sum + (task.completed ? task.getStudyMinutes() : 0),
      );
    }

    setState(() {
      _totalTasks = allTasks.length;
      _tasksCompleted = completedTasks.length;
      _progressPercent = _totalTasks == 0 ? 0.0 : _tasksCompleted / _totalTasks;
      _totalMinutesStudied = totalMinutes;
      _todayMinutes = todayMinutes;
      _weekMinutes = weekMinutes;
      _dailyMinutes = dailyMinutes;
    });
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes} min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0 ? '${hours}h ${remainingMinutes} min' : '${hours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final currentTheme = themeNotifier.themeMode == ThemeMode.light
        ? themeNotifier.lightTheme
        : themeNotifier.darkTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresso'),
        backgroundColor: themeNotifier.themeMode == ThemeMode.light
            ? currentTheme.colorScheme.primary
            : const Color.fromARGB(255, 4, 10, 14),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SettingsDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo do progresso',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(8),
                  value: _progressPercent,
                  minHeight: 24,
                  backgroundColor: currentTheme.colorScheme.primary.withAlpha(50),
                  color: currentTheme.colorScheme.primary,
                ),
                Text(
                  '${(_progressPercent * 100).toStringAsFixed(0)}% Concluídos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statCard(
                  'Tempo Total',
                  _formatTime(_totalMinutesStudied),
                  Icons.timer,
                  currentTheme,
                ),
                _statCard(
                  'Hoje',
                  _formatTime(_todayMinutes),
                  Icons.today,
                  currentTheme,
                ),
                _statCard(
                  'Esta Semana',
                  _formatTime(_weekMinutes),
                  Icons.date_range,
                  currentTheme,
                ),
                _statCard(
                  'Tarefas',
                  '$_tasksCompleted / $_totalTasks',
                  Icons.check_circle,
                  currentTheme,
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'Estudo por dia da semana',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentTheme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: _buildBarChart(currentTheme),
            ),
            const SizedBox(height: 24),
            if (_totalTasks > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentTheme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${((_progressPercent) * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: currentTheme.colorScheme.primary,
                          ),
                        ),
                        const Text('Progresso'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${_totalTasks - _tasksCompleted}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: currentTheme.colorScheme.error,
                          ),
                        ),
                        const Text('Pendentes'),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      elevation: 2,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(ThemeData theme) {
    final maxMinutes = _dailyMinutes.isEmpty
        ? 1
        : (_dailyMinutes.reduce((a, b) => a > b ? a : b)).clamp(1, double.infinity);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final barHeight = maxMinutes > 0 ? (_dailyMinutes[i] / maxMinutes) * 140 : 0.0;
        final isToday = DateTime.now().weekday % 7 == i;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_dailyMinutes[i] > 0)
              Text(
                _formatTime(_dailyMinutes[i]),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: barHeight.clamp(4.0, 140.0),
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
                border: isToday
                    ? Border.all(color: theme.colorScheme.secondary, width: 2)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _weekDays[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      }),
    );
  }
}