import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/task.dart';

class PomodoroNotifier extends ChangeNotifier {
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 25);
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

  // Getter público para as chaves das sessões de foco
  Iterable<String> get focusSessionKeys => _focusDurations.keys;

  Duration get remaining => _remaining;
  bool get isRunning => _isRunning;
  bool get isFocus => _isFocus;
  Task? get selectedTask => _selectedTask;
  String get selectedSession => _selectedSession;

  PomodoroNotifier() {
    _remaining = _focusDurations[_selectedSession]!;
  }

  void setSession(String session) {
    if (_selectedSession != session && !_isRunning) {
      _selectedSession = session;
      _remaining = _isFocus
          ? _focusDurations[session]!
          : _breakDurations[session]!;
      notifyListeners();
    }
  }

  void selectTask(Task? task) {
    _selectedTask = task;
    notifyListeners();
  }

  void startTimer() {
    if (_selectedTask == null) return;
    _sessionStartTime = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) {
        _toggleSession();
      } else {
        _remaining -= const Duration(seconds: 1);
        notifyListeners();
      }
    });
    _isRunning = true;
    notifyListeners();
  }

  void _toggleSession() async {
    _timer?.cancel();
    if (_isFocus && _selectedTask != null) {
      final endTime = DateTime.now();
      await DatabaseService.updateTaskTime(
        _selectedTask!.id!,
        _sessionStartTime?.millisecondsSinceEpoch,
        endTime.millisecondsSinceEpoch,
      );
    }
    _isFocus = !_isFocus;
    _remaining = _isFocus
        ? _focusDurations[_selectedSession]!
        : _breakDurations[_selectedSession]!;
    if (_isFocus && _selectedTask != null) {
      startTimer();
    } else {
      _isRunning = false;
    }
    notifyListeners();
  }

  void toggleStartPause() {
    if (_isRunning) {
      _timer?.cancel();
      if (_isFocus && _selectedTask != null) {
        // Aqui você precisa passar o tempo gasto nessa sessão, que pode ser calculado
        final nowMillis = DateTime.now().millisecondsSinceEpoch;
        final startMillis =
            _sessionStartTime?.millisecondsSinceEpoch ?? nowMillis;
        final elapsedMillis = nowMillis - startMillis;

        DatabaseService.updateTaskTime(
          _selectedTask!.id!,
          null, // Se quiser atualizar pomodoroCount, passe o valor aqui, ou null para não alterar
          elapsedMillis ~/ 1000, // tempo em segundos
        );
      }
      _isRunning = false;
    } else {
      if (_selectedTask == null) return;
      if (_remaining == Duration.zero) {
        _remaining = _isFocus
            ? _focusDurations[_selectedSession]!
            : _breakDurations[_selectedSession]!;
      }
      startTimer();
    }
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    if (_isFocus && _selectedTask != null) {
      DatabaseService.updateTaskTime(_selectedTask!.id!, null, null);
    }
    _isRunning = false;
    _isFocus = true;
    _remaining = _focusDurations[_selectedSession]!;
    _sessionStartTime = null;
    notifyListeners();
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  double getProgress() {
    final total = _isFocus
        ? _focusDurations[_selectedSession]!.inSeconds
        : _breakDurations[_selectedSession]!.inSeconds;
    return total == 0 ? 0.0 : 1.0 - (_remaining.inSeconds / total);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
