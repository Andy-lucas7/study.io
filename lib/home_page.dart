import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/tasks_page.dart';
import 'screens/pomodoro_page.dart';
import 'notifiers/environment_notifier.dart';
import 'screens/environment_sound_page.dart';
import 'screens/summary_page.dart';
import 'screens/progress_page.dart';
import 'notifiers/theme_notifier.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const TasksPage(),
    const PomodoroPage(),
    const EnvironmentSoundPage(),
    const SummaryPage(),
    const ProgressPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final env = context.read<EnvironmentNotifier>();
    final sound = env.environment.name.toLowerCase();
    String soundLabel;
    if (sound == 'coffee') {
      soundLabel = 'som de cafeteria';
    } else if (sound == 'rain') {
      soundLabel = 'som de chuva';
    } else if (sound == 'forest') {
      soundLabel = 'som de floresta';
    } else if (sound == 'mute') {
      soundLabel = 'sem som';
    } else {
      soundLabel = sound;
    }

    final currentTheme = themeNotifier.themeMode == ThemeMode.light
        ? themeNotifier.lightTheme
        : themeNotifier.darkTheme;
    return Scaffold(
      backgroundColor: themeNotifier.darkTheme.scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: themeNotifier.themeMode == ThemeMode.light
            ? currentTheme.colorScheme.primary
            : const Color.fromARGB(255, 4, 10, 14),
        selectedItemColor: themeNotifier.themeMode == ThemeMode.light
            ? Colors.white
            : env.environment == Environment.coffee
            ? currentTheme.colorScheme.onPrimary
            : currentTheme.colorScheme.primary,
        unselectedItemColor: themeNotifier.themeMode == ThemeMode.light
            ? currentTheme.colorScheme.secondary
            : Colors.white70,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        },
        type: BottomNavigationBarType.shifting,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Tarefas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Pomodoro'),
          BottomNavigationBarItem(
            icon: Icon(Icons.surround_sound_rounded),
            label: soundLabel,
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Resumos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progresso',
          ),
        ],
      ),
    );
  }
}
