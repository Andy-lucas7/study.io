import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_io/core/app_config.dart';
import '../notifiers/pomodoro_notifier.dart';
import '../services/database_service.dart';
import '../widgets/settings_drawer.dart';
import 'package:intl/intl.dart';

class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key});

  Future<void> _selectTask(
    BuildContext context,
    PomodoroNotifier notifier,
  ) async {
    final tasks = await DatabaseService.getTasksByDate(
      DateTime.now(),
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
                title: Text(task.title, textAlign: TextAlign.center),
                onTap: () {
                  notifier.selectTask(task);
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

  @override
  Widget build(BuildContext context) {
    final pomodoroNotifier = context.watch<PomodoroNotifier>();
    final currentTheme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Timer Pomodoro', style: AppConfig().montserratTitle),
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
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.37,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppConfig.tile,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      menuWidth: 230,
                      isDense: true,
                      isExpanded: true,
                      alignment: Alignment.center,
                      borderRadius: BorderRadius.circular(20),
                      dropdownColor: const Color.fromARGB(
                        65,
                        27,
                        27,
                        27,
                      ).withOpacity(0.85),
                      value: pomodoroNotifier.selectedSession,
                      icon: Icon(
                        color: Colors.white,
                        Icons.keyboard_arrow_down_rounded,
                      ),
                      style: AppConfig().montserratTitle.copyWith(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      onChanged: pomodoroNotifier.isRunning
                          ? null
                          : (value) {
                              if (value != null) {
                                pomodoroNotifier.setSession(value);
                              }
                            },
                      items: pomodoroNotifier.focusSessionKeys.map((label) {
                        return DropdownMenuItem(
                          alignment: Alignment.center,
                          value: label,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return pomodoroNotifier.focusSessionKeys.map((label) {
                          String displayLabel;
                          switch (label) {
                            case 'Iniciante 10 min | 5 min':
                              displayLabel = 'Iniciante';
                              break;
                            case 'Clássico 25 min | 5 min':
                              displayLabel = 'Clássico';
                              break;
                            case 'Produtivo 30 min | 10 min':
                              displayLabel = 'Produtivo';
                              break;
                            case 'Intermediário 1H | 15 min':
                              displayLabel = 'Intermediário';
                              break;
                            case 'Avançado 1H30 | 20 min':
                              displayLabel = 'Avançado';
                              break;
                            case 'Mestre do Foco 3H | 30 min':
                              displayLabel = 'Mestre do Foco';
                              break;
                            default:
                              displayLabel = label;
                          }
                          return Center(
                            child: Text(
                              displayLabel,
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pomodoroNotifier.isFocus ? 'Modo: Foco' : 'Modo: Pausa',
                    style: AppConfig().montserratTitle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 22),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: pomodoroNotifier.remaining == Duration.zero
                              ? 0.0
                              : pomodoroNotifier.getProgress(),
                          strokeWidth: 16,
                          valueColor: AlwaysStoppedAnimation(
                            currentTheme.colorScheme.primary,
                          ),
                          backgroundColor: currentTheme.colorScheme.primary
                              .withOpacity(0.3),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pomodoroNotifier.formatDuration(
                              pomodoroNotifier.remaining,
                            ),
                            style: AppConfig().quicksandTitle.copyWith(
                              fontSize: 58,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _selectTask(context, pomodoroNotifier),
                            child: Text(
                              pomodoroNotifier.selectedTask?.title ??
                                  'Selecionar Tarefa',
                              style: TextStyle(
                                color: currentTheme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: pomodoroNotifier.selectedTask == null
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selecione uma tarefa antes de iniciar.',
                              ),
                            ),
                          );
                        }
                      : pomodoroNotifier.toggleStartPause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.colorScheme.primary,
                  ),
                  icon: Icon(
                    pomodoroNotifier.isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  label: Text(
                    pomodoroNotifier.isRunning ? 'Pausar' : 'Iniciar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      pomodoroNotifier.isRunning ||
                          pomodoroNotifier.remaining > Duration.zero
                      ? pomodoroNotifier.resetTimer
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
