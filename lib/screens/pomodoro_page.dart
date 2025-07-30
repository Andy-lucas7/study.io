import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/theme_notifier.dart';
import '../services/database_service.dart';
import '../models/task.dart';
import '../widgets/settings_drawer.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  bool _isRunning = false;
  bool _isFocus = true;
  Task? _selectedTask;
  DateTime? _sessionStartTime;

  String _selectedSession = 'Clássico 25 min | 5 min';
  final Map<String, Duration> _focusDurations = {
    'Iniciante 10 min | 5 min': const Duration(minutes: 10),
    'Clássico 25 min | 5 min': const Duration(minutes: 25),
    'Produtivo 30 min | 10 min': const Duration(minutes: 30),
    'Intermediário 1H | 15 min': const Duration(minutes: 60),
    'Avançado 1H30 | 20 min': const Duration(minutes: 90),
    'Mestre do Foco 3H | 30 min': const Duration(minutes: 180),
  };

  final Map<String, Duration> _breakDurations = {
    'Iniciante 10 min | 5 min': const Duration(minutes: 5),
    'Clássico 25 min | 5 min': const Duration(minutes: 5),
    'Produtivo 30 min | 10 min': const Duration(minutes: 10),
    'Intermediário 1H | 15 min': const Duration(minutes: 15),
    'Avançado 1H30 | 20 min': const Duration(minutes: 20),
    'Mestre do Foco 3H | 30 min': const Duration(minutes: 30),
  };

  Future<void> _selectTask() async {
    final tasks = await DatabaseService.getTasksByDate(
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma tarefa disponível para hoje.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Tarefa'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.title),
                onTap: () {
                  setState(() {
                    _selectedTask = task;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    if (_selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma tarefa antes de iniciar.')),
      );
      return;
    }
    _sessionStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) {
        _toggleSession();
      } else {
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _toggleSession() async {
    _timer.cancel();
    if (_isFocus && _selectedTask != null) {
      final endTime = DateTime.now();
      await DatabaseService.updateTaskTime(
        _selectedTask!.id!,
        _sessionStartTime,
        endTime,
      );
    }
    setState(() {
      _isFocus = !_isFocus;
      _remaining = _isFocus
          ? _focusDurations[_selectedSession]!
          : _breakDurations[_selectedSession]!;
    });
    if (_isFocus) {
      _startTimer();
    }
  }

  void _handleStartPause() {
    if (_isRunning) {
      _timer.cancel();
      if (_isFocus && _selectedTask != null) {
        DatabaseService.updateTaskTime(
          _selectedTask!.id!,
          _sessionStartTime,
          DateTime.now(),
        );
      }
      setState(() {
        _isRunning = false;
      });
    } else {
      if (_remaining == Duration.zero) {
        setState(() {
          _remaining = _isFocus
              ? _focusDurations[_selectedSession]!
              : _breakDurations[_selectedSession]!;
        });
      }
      _startTimer();
      setState(() {
        _isRunning = true;
      });
    }
  }

  void _resetTimer() {
    _timer.cancel();
    if (_isFocus && _selectedTask != null) {
      DatabaseService.updateTaskTime(_selectedTask!.id!, null, null);
    }
    setState(() {
      _isRunning = false;
      _isFocus = true;
      _remaining = Duration.zero;
      _sessionStartTime = null;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  double _getProgress() {
    final total = _isFocus
        ? _focusDurations[_selectedSession]!.inSeconds
        : _breakDurations[_selectedSession]!.inSeconds;
    return 1.0 - (_remaining.inSeconds / total);
  }

  @override
  void dispose() {
    if (_isRunning) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final currentTheme = themeNotifier.themeMode == ThemeMode.light
        ? themeNotifier.lightTheme
        : themeNotifier.darkTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Timer Pomodoro', style: AppFonts().montserratTitle),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200.0,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSession,
                    onChanged: _isRunning
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSession = value;
                                _remaining = Duration.zero;
                              });
                            }
                          },
                    items: _focusDurations.keys.map((label) {
                      return DropdownMenuItem(value: label, child: Text(label));
                    }).toList(),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: _remaining == Duration.zero
                            ? 0.0
                            : _getProgress(),
                        strokeWidth: 16,
                        valueColor: AlwaysStoppedAnimation(
                          currentTheme.colorScheme.primary,
                        ),
                        backgroundColor: Colors.grey.shade300,
                        strokeCap:
                            StrokeCap.round, // Deixa as pontas arredondadas
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isFocus ? 'FOCO' : 'PAUSA',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatDuration(_remaining),
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        ElevatedButton(
                          onPressed: _selectTask,
                          child: Text(
                            _selectedTask?.title ?? 'Selecionar Tarefa',
                            style: TextStyle(
                              color: currentTheme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _handleStartPause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.colorScheme.primary,
                  ),
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isRunning ? 'Pausar' : 'Iniciar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning || _remaining > Duration.zero
                      ? _resetTimer
                      : null,
                  icon: const Icon(Icons.replay),
                  label: const Text('Resetar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
