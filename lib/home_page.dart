import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/tasks_page.dart';
import 'screens/pomodoro_page.dart';
import 'notifiers/environment_notifier.dart';
import 'screens/environment_sound_page.dart';
import 'screens/summary_page.dart';
import 'screens/progress_page.dart';
import 'notifiers/theme_notifier.dart';
import 'constants.dart';

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
    Icon environmentIconSound;
    String soundLabel;
    if (sound == 'coffee') {
      soundLabel = 'som de cafeteria';
      environmentIconSound = Icon(Icons.coffee);
    } else if (sound == 'rain') {
      soundLabel = 'som de chuva';
      environmentIconSound = Icon(Icons.water_drop_rounded);
    } else if (sound == 'forest') {
      soundLabel = 'som de floresta';
      environmentIconSound = Icon(Icons.forest_rounded);
    } else if (sound == 'mute') {
      soundLabel = 'sem som';
      environmentIconSound = Icon(Icons.music_off_rounded);
    } else {
      soundLabel = sound;
      environmentIconSound = Icon(Icons.music_off_rounded);
    }

    final currentTheme = themeNotifier.themeMode == ThemeMode.light
        ? themeNotifier.lightTheme
        : themeNotifier.darkTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.tile,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2), 
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: SizedBox(
            height: 80,
            child: BottomNavigationBar(
              iconSize: 32,
              currentIndex: _currentIndex,
              backgroundColor: const Color.fromARGB(0, 108, 26, 26),
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.ease,
                );
              },
              type: BottomNavigationBarType.shifting,
              items: [
                BottomNavigationBarItem(
                  backgroundColor: AppColors.tile,
                  icon: Icon(Icons.check_circle),
                  label: 'Tarefas',
                ),
                BottomNavigationBarItem(
                  backgroundColor: AppColors.tile,
                  icon: Icon(Icons.timer),
                  label: 'Pomodoro',
                ),
                BottomNavigationBarItem(
                  backgroundColor: AppColors.tile,
                  icon: environmentIconSound,
                  label: soundLabel,
                ),
                BottomNavigationBarItem(
                  backgroundColor: AppColors.tile,
                  icon: Icon(Icons.article),
                  label: 'Resumos',
                ),
                BottomNavigationBarItem(
                  backgroundColor: AppColors.tile,
                  icon: Icon(Icons.bar_chart),
                  label: 'Progresso',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
