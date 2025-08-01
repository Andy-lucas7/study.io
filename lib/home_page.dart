import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/tasks_page.dart';
import 'screens/pomodoro_page.dart';
import 'notifiers/environment_notifier.dart';
import 'screens/environment_sound_page.dart';
import 'screens/summary_page.dart';
import 'screens/progress_page.dart';
import 'notifiers/theme_notifier.dart';
import 'styles.dart';

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
    final backgroundImagePath = context.watch<EnvironmentNotifier>().backgroundImagePath;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final env = context.read<EnvironmentNotifier>();
    final sound = env.environment.name.toLowerCase();
    Icon environmentIconSound;
    String soundLabel;
    if (sound == 'coffee') {
      soundLabel = 'som de cafeteria';
      environmentIconSound = const Icon(Icons.coffee);
    } else if (sound == 'rain') {
      soundLabel = 'som de chuva';
      environmentIconSound = const Icon(Icons.water_drop_rounded);
    } else if (sound == 'forest') {
      soundLabel = 'som de floresta';
      environmentIconSound = const Icon(Icons.forest_rounded);
    } else if (sound == 'mute') {
      soundLabel = 'sem som';
      environmentIconSound = const Icon(Icons.music_off_rounded);
    } else {
      soundLabel = sound;
      environmentIconSound = const Icon(Icons.music_off_rounded);
    }

    final currentTheme = themeNotifier.themeMode == ThemeMode.light
        ? themeNotifier.lightTheme
        : themeNotifier.darkTheme;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: backgroundImagePath.isNotEmpty
                ? Image.asset(
                    backgroundImagePath,
                    key: ValueKey(backgroundImagePath),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  )
                : Container(
                    key: const ValueKey('empty'),
                    color: AppColors.background,
                  ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            physics: const PageScrollPhysics(),
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
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
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
                right: Radius.circular(20),
              ),
              child: SizedBox(
                height: 80,
                child: BottomNavigationBar(
                  iconSize: 32,
                  currentIndex: _currentIndex,
                  backgroundColor: Colors.transparent,
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
                      backgroundColor: AppColors.background,
                      icon: const Icon(Icons.check_circle),
                      label: 'Tarefas',
                    ),
                    BottomNavigationBarItem(
                      backgroundColor: AppColors.background,
                      icon: const Icon(Icons.timer),
                      label: 'Pomodoro',
                    ),
                    BottomNavigationBarItem(
                      backgroundColor: AppColors.background,
                      icon: environmentIconSound,
                      label: soundLabel,
                    ),
                    BottomNavigationBarItem(
                      backgroundColor: AppColors.background,
                      icon: const Icon(Icons.article),
                      label: 'Resumos',
                    ),
                    BottomNavigationBarItem(
                      backgroundColor: AppColors.background,
                      icon: const Icon(Icons.bar_chart),
                      label: 'Progresso',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}