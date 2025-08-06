import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/tasks_page.dart';
import 'screens/pomodoro_page.dart';
import 'screens/environment_sound_page.dart';
import 'screens/summary_page.dart';
import 'screens/progress_page.dart';
import 'core/app_config.dart';
import 'package:hugeicons/hugeicons.dart';

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
    final backgroundImagePath = context
        .watch<EnvironmentNotifier>()
        .backgroundImagePath;
    final env = context.read<EnvironmentNotifier>();
    final sound = env.environment.name.toLowerCase();
    Icon environmentIconSound;
    String soundLabel;
    if (sound == 'coffee') {
      soundLabel = 'som de cafeteria';
      environmentIconSound = Icon(HugeIcons.strokeRoundedCoffee02);
    } else if (sound == 'rain') {
      soundLabel = 'som de chuva';
      environmentIconSound = Icon(HugeIcons.strokeRoundedCloud);
    } else if (sound == 'forest') {
      soundLabel = 'som de floresta';
      environmentIconSound = Icon(HugeIcons.strokeRoundedPineTree);
    } else if (sound == 'mute') {
      soundLabel = 'sem som';
      environmentIconSound = Icon(HugeIcons.strokeRoundedVolumeMute02);
    } else if (sound == 'white') {
      soundLabel = 'som branco';
      environmentIconSound = Icon(HugeIcons.strokeRoundedVoice);
    } else {
      soundLabel = sound;
      environmentIconSound = Icon(HugeIcons.strokeRoundedVolumeMute02);
    }

    final currentTheme = Theme.of(context);

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
                    color: AppConfig.background,
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
                  selectedItemColor: env.environment == Environment.coffee
                      ? currentTheme.colorScheme.onPrimary
                      : currentTheme.colorScheme.primary,
                  unselectedItemColor:
                  currentTheme.colorScheme.secondary,
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
                      backgroundColor: AppConfig.background.withOpacity(0.34),
                      icon: Icon(HugeIcons.strokeRoundedTask01),
                      label: 'Tarefas',
                    ),
                    BottomNavigationBarItem(
                      backgroundColor: AppConfig.background.withOpacity(0.34),
                      icon: Icon(HugeIcons.strokeRoundedClock01),
                      label: 'Pomodoro',
                    ),
                    BottomNavigationBarItem(
                      backgroundColor: AppConfig.background.withOpacity(0.34),
                      icon: environmentIconSound,
                      label: soundLabel,
                    ),
                    BottomNavigationBarItem(
                      backgroundColor: AppConfig.background.withOpacity(0.34),
                      icon: Icon(HugeIcons.strokeRoundedBook02),
                      label: 'Resumos',
                    ),
                    BottomNavigationBarItem(
                      backgroundColor: AppConfig.background.withOpacity(0.34),
                      icon: Icon(HugeIcons.strokeRoundedBarChart),
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
