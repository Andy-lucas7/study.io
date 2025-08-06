import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_io/screens/new_task_page.dart';
import 'package:study_io/widgets/settings_drawer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'about_task_page.dart';
import '../core/app_config.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  Map<DateTime, List<Task>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  List<Task> _selectedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadTasks();
  }

  // Função para carregar tarefas do banco
  Future<void> _loadTasks() async {
    try {
      setState(() => _isLoading = true);
      await initializeDateFormatting('pt_BR', null);

      final tasks = await DatabaseService.getTasks();
      final Map<DateTime, List<Task>> eventMap = {};

      // Organiza as tarefas por data
      for (var task in tasks) {
        final taskDate = DateTime.parse(task.date);
        final day = DateTime(taskDate.year, taskDate.month, taskDate.day);
        eventMap.putIfAbsent(day, () => []).add(task);
      }

      setState(() {
        _events = eventMap;
        _selectedTasks = _getTasksForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar tarefas: $e')));
      }
    }
  }

  // Função para obter tarefas de um dia específico
  List<Task> _getTasksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // Função para lidar com seleção de dia
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedTasks = _getTasksForDay(selectedDay);
      });
    }
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

  Widget _buildTaskItem(Task task, int index) {
    final currentTheme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AboutTaskPage(task: task)),
        );

        if (result == true) {
          _loadTasks();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: task.description.isNotEmpty
                ? Text(
                    task.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            leading: Container(
              width: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: currentTheme.colorScheme.primary,
              ),
              child: Text(
                task.startTime.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final selectedDateFormatted = _selectedDay != null
        ? DateFormat("d 'de' MMMM", 'PT_BR').format(_selectedDay!)
        : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.5),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
            tooltip: 'Atualizar',
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      drawer: SettingsDrawer(),
      body: SafeArea(
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
                locale: 'pt_br',
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
                  weekdayStyle: TextStyle(
                    color: Colors.white70,
                  ),
                  weekendStyle: TextStyle(
                    color: currentTheme.colorScheme.primary
                  )
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: currentTheme.colorScheme.secondary.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: currentTheme.colorScheme.primary.withOpacity(0.3), width: 2.3)
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
                  weekendTextStyle:  TextStyle(color: Colors.white70),
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

            // Tasks list
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToNewTaskPage(),
        backgroundColor: currentTheme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
