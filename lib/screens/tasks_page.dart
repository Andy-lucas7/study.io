import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_io/screens/new_task_page.dart';
import 'package:study_io/widgets/settings_drawer.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'about_task_page.dart';
import '../core/app_config.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  Map<DateTime, List<Task>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  List<Task> _selectedTasks = [];
  bool _isLoading = true;
  bool _isInitialLoad = true;

  // Cache para otimização e detecção de mudanças
  List<Task> _allTasks = [];
  DateTime? _lastLoadTime;
  String? _lastTasksHash; // Hash para detectar mudanças
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // IDs das tasks em modo "delete"
  final Set<String> _deleteModeTaskIds = {};
  
  // Controllers de animação
  late AnimationController _deleteAnimationController;
  late AnimationController _listAnimationController;
  
  // GlobalKey para animações da lista
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    
    // Inicializa controllers de animação
    _deleteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Observer para detectar quando o app volta do background
    WidgetsBinding.instance.addObserver(this);
    
    _loadTasks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deleteAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Quando o app volta do background, verifica se há mudanças
    if (state == AppLifecycleState.resumed) {
      _checkForChangesAndReload();
    }
  }

  // Gera hash das tasks para detectar mudanças
  String _generateTasksHash(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) => a.id!.compareTo(b.id!));
    
    final hashString = sortedTasks.map((task) => 
      '${task.id}-${task.title}-${task.completed}-${task.date.millisecondsSinceEpoch}'
    ).join('|');
    
    return hashString.hashCode.toString();
  }

  // Verifica se há mudanças e recarrega apenas se necessário
  Future<void> _checkForChangesAndReload() async {
    try {
      final tasks = await DatabaseService.getTasks();
      final newHash = _generateTasksHash(tasks);
      
      // Só atualiza se o hash mudou (houve alterações reais)
      if (_lastTasksHash != newHash) {
        _allTasks = tasks;
        _lastTasksHash = newHash;
        _lastLoadTime = DateTime.now();
        
        _updateEventsMap();
        
        setState(() {
          _selectedTasks = _getTasksForDay(_selectedDay!);
        });
        
        _listAnimationController.reset();
        _listAnimationController.forward();
      }
    } catch (e) {
      // Silenciosamente ignora erros na verificação em background
      debugPrint('Erro ao verificar mudanças: $e');
    }
  }

  // Verifica se o cache ainda é válido
  bool get _isCacheValid {
    if (_lastLoadTime == null) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  Future<void> _loadTasks({bool forceReload = false}) async {
    // Se é apenas uma verificação de rotina e o cache é válido, usa a verificação inteligente
    if (!forceReload && !_isInitialLoad && _isCacheValid) {
      await _checkForChangesAndReload();
      return;
    }

    try {
      // Só mostra loading na primeira vez ou em reloads forçados
      if (_isInitialLoad || forceReload) {
        setState(() => _isLoading = true);
      }
      
      await initializeDateFormatting('pt_BR', null);

      final tasks = await DatabaseService.getTasks();
      final newHash = _generateTasksHash(tasks);
      
      // Verifica se realmente há mudanças
      if (!forceReload && _lastTasksHash == newHash && !_isInitialLoad) {
        setState(() => _isLoading = false);
        return;
      }
      
      _allTasks = tasks;
      _lastTasksHash = newHash;
      _lastLoadTime = DateTime.now();
      
      _updateEventsMap();
      
      setState(() {
        _selectedTasks = _getTasksForDay(_selectedDay!);
        _isLoading = false;
        _isInitialLoad = false;
      });
      
      // Anima a lista quando carrega
      _listAnimationController.reset();
      _listAnimationController.forward();
      
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar tarefas: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _updateEventsMap() {
    final Map<DateTime, List<Task>> eventMap = {};
    
    for (var task in _allTasks) {
      final day = DateTime(task.date.year, task.date.month, task.date.day);
      eventMap.putIfAbsent(day, () => []).add(task);
    }
    
    _events = eventMap;
  }

  List<Task> _getTasksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedTasks = _getTasksForDay(selectedDay);
        _deleteModeTaskIds.clear();
      });
      
      // Reinicia animação da lista
      _listAnimationController.reset();
      _listAnimationController.forward();
    }
  }

  Future<void> _goToNewTaskPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewTaskPage()),
    );

    if (result == true) {
      await _loadTasks(forceReload: true);
    }
  }

  // Alterna modo delete do tile com animação
  void _toggleDeleteMode(String taskId) {
    setState(() {
      if (_deleteModeTaskIds.contains(taskId)) {
        _deleteModeTaskIds.remove(taskId);
      } else {
        _deleteModeTaskIds.add(taskId);
      }
    });
    // Pequena vibração para feedback tátil
    HapticFeedback.selectionClick();
  }

  // Deleta tarefa com animação otimista
  Future<void> _deleteTask(String taskId) async {
    // Encontra a task e sua posição
    final taskIndex = _selectedTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final taskToDelete = _selectedTasks[taskIndex];
    
    // Remove otimisticamente da UI
    setState(() {
      _selectedTasks.removeAt(taskIndex);
      _deleteModeTaskIds.remove(taskId);
    });
    
    // Remove do cache local
    _allTasks.removeWhere((task) => task.id == taskId);
    _updateEventsMap();
    
    try {
      // Faz a operação no banco de dados em background
      await DatabaseService.deleteTask(taskId);
      
      // Mostra feedback de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Tarefa "${taskToDelete.title}" removida'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Desfazer',
              textColor: Colors.white,
              onPressed: () => _undoDeleteTask(taskToDelete, taskIndex),
            ),
          ),
        );
      }
    } catch (e) {
      // Restaura na UI e atualiza cache
      setState(() {
        _selectedTasks.insert(taskIndex, taskToDelete);
        _deleteModeTaskIds.remove(taskId);
        _allTasks.add(taskToDelete);
        _lastTasksHash = _generateTasksHash(_allTasks);
        _updateEventsMap();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir tarefa: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Funcionalidade de desfazer exclusão
  Future<void> _undoDeleteTask(Task task, int originalIndex) async {
    try {
      // Recria a task no banco de dados
      await DatabaseService.insertTask(task);
      
      // Restaura na UI e atualiza cache
      setState(() {
        _selectedTasks.insert(
          originalIndex.clamp(0, _selectedTasks.length),
          task,
        );
        _allTasks.add(task);
        _lastTasksHash = _generateTasksHash(_allTasks);
        _updateEventsMap();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.restore, color: Colors.white),
                SizedBox(width: 8),
                Text('Tarefa restaurada'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar tarefa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Marca ou desmarca conclusão com update otimista
  Future<void> _toggleTaskCompletion(Task task) async {
    final taskIndex = _selectedTasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    // Update otimista na UI
    final updatedTask = task.copyWith(completed: !task.completed);
    setState(() {
      _selectedTasks[taskIndex] = updatedTask;
    });
    
    // Update no cache local e hash
    final cacheIndex = _allTasks.indexWhere((t) => t.id == task.id);
    if (cacheIndex != -1) {
      _allTasks[cacheIndex] = updatedTask;
      _lastTasksHash = _generateTasksHash(_allTasks);
    }

    try {
      // Update no banco de dados em background
      await DatabaseService.updateTask(updatedTask);
    } catch (e) {
      // Se falhar, reverte o estado e hash
      setState(() {
        _selectedTasks[taskIndex] = task;
      });
      
      if (cacheIndex != -1) {
        _allTasks[cacheIndex] = task;
        _lastTasksHash = _generateTasksHash(_allTasks);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar tarefa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTaskItem(Task task, int index) {
    final currentTheme = Theme.of(context);
    final isInDeleteMode = _deleteModeTaskIds.contains(task.id);

    String hourPeriod = '';
    if (task.startTime != null && task.endTime != null) {
      final startTime = DateFormat('H:mm').format(task.startTime!);
      final endTime = DateFormat('H:mm').format(task.endTime!);
      hourPeriod = '$startTime - $endTime';
    } else {
      hourPeriod = 'Horário não definido';
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _listAnimationController,
        curve: Interval(
          (index * 0.1).clamp(0.0, 1.0),
          ((index * 0.1) + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      )),
      child: FadeTransition(
        opacity: _listAnimationController,
        child: GestureDetector(
          onTap: () async {
            if (isInDeleteMode) {
              _toggleDeleteMode(task.id!);
            } else {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AboutTaskPage(task: task)),
              );
              if (result == true) {
                _loadTasks(forceReload: true);
              }
            }
          },
          onLongPress: () {
            _toggleDeleteMode(task.id!);
            HapticFeedback.mediumImpact();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              transform: Matrix4.identity()
                ..scale(isInDeleteMode ? 0.98 : 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isInDeleteMode
                    ? Colors.red.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
                border: isInDeleteMode
                    ? Border.all(color: Colors.red.withOpacity(0.2), width: 1)
                    : null,
                boxShadow: isInDeleteMode
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isInDeleteMode ? Colors.red.shade300 : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                  ),
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                subtitle: task.description.isNotEmpty
                    ? AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isInDeleteMode 
                              ? Colors.red.shade200.withOpacity(0.7)
                              : Colors.white70,
                          fontSize: 14,
                        ),
                        child: Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : null,
                leading: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 35,
                  width: 85,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isInDeleteMode
                        ? Colors.red.withOpacity(0.3)
                        : currentTheme.colorScheme.primary,
                  ),
                  child: Text(
                    hourPeriod,
                    style: AppConfig().roboto.copyWith(
                      fontSize: 10,
                      color: isInDeleteMode ? Colors.red.shade100 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: isInDeleteMode
                      ? Container(
                          key: const ValueKey('delete'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.2),
                          ),
                          child: IconButton(
                            icon: Icon(
                              HugeIcons.strokeRoundedDelete02,
                              color: Colors.red,
                            ),
                            onPressed: () => _showDeleteConfirmation(task),
                            tooltip: 'Excluir tarefa',
                          ),
                        )
                      : Container(
                          key: const ValueKey('checkbox'),
                          child: Checkbox(
                            value: task.completed,
                            onChanged: (_) => _toggleTaskCompletion(task),
                            activeColor: currentTheme.colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Confirmação de exclusão com dialog bonito
  Future<void> _showDeleteConfirmation(Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirmar exclusão',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Tem certeza que deseja excluir a tarefa "${task.title}"?\n\nEsta ação não pode ser desfeita.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Excluir',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteTask(task.id!);
    }
  }

  Widget _buildEmptyState() {
    final selectedDateFormatted = _selectedDay != null
        ? DateFormat("d 'de' MMMM", 'pt_BR').format(_selectedDay!)
        : '';

    return FadeTransition(
      opacity: _listAnimationController,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      HugeIcons.strokeRoundedTaskDone01,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma tarefa para $selectedDateFormatted',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Adicione uma nova tarefa para começar!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentTheme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Container(),
        ),
        title: Text("Tarefas", style: AppConfig().montserratTitle),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset('assets/icon/Icon_fill.png'),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _listAnimationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _listAnimationController.value * 2 * 3.14159,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadTasks(forceReload: true),
                  tooltip: 'Atualizar',
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      drawer: const SettingsDrawer(),
      body: RefreshIndicator(
        onRefresh: () => _loadTasks(forceReload: true),
        color: currentTheme.colorScheme.primary,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TableCalendar<Task>(
                  locale: 'pt_BR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: _getTasksForDay,
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.white70),
                    weekendStyle: TextStyle(
                      color: currentTheme.colorScheme.primary,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: currentTheme.colorScheme.secondary.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentTheme.colorScheme.primary.withOpacity(0.3),
                        width: 2.3,
                      ),
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: TextStyle(color: Colors.white70),
                    markerDecoration: BoxDecoration(
                      color: currentTheme.colorScheme.onPrimary,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    formatButtonTextStyle: TextStyle(color: Colors.white),
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white54, width: 1),
                      ),
                    ),
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _selectedTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            itemCount: _selectedTasks.length,
                            itemBuilder: (context, index) {
                              return _buildTaskItem(_selectedTasks[index], index);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _listAnimationController,
            curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
          ),
        ),
        child: FloatingActionButton(
          onPressed: () => _goToNewTaskPage(),
          backgroundColor: currentTheme.colorScheme.primary,
          child: const Icon(
            HugeIcons.strokeRoundedTaskAdd01,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}