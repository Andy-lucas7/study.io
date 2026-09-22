import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/tasks_page.dart';
import 'screens/pomodoro_page.dart';
import 'screens/environment_sound_page.dart';
import 'screens/summary_page.dart';
import 'screens/progress_page.dart';
import 'core/app_config.dart';
import 'package:hugeicons/hugeicons.dart';
import 'widgets/settings_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double _iconOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (!_pageController.hasClients) return;
      final page = _pageController.page ?? 0.0;
      final distance = (page - page.round()).abs();
      setState(() {
        _iconOpacity = (1.0 - (distance * 4)).clamp(0.0, 1.0);
      });
    });
  }

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

  Widget _buildNavItem(int index, IconData iconData, Color primaryColor) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 24 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            iconData,
            key: ValueKey<bool>(isSelected),
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            size: isSelected ? 28 : 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImagePath = context
        .watch<EnvironmentNotifier>()
        .backgroundImagePath;
    final env = context.read<EnvironmentNotifier>();
    final sound = env.environment.name.toLowerCase();
    Icon environmentIconSound;
    if (sound == 'coffee') {
      environmentIconSound = const Icon(HugeIcons.strokeRoundedCoffee02);
    } else if (sound == 'rain') {
      environmentIconSound = const Icon(HugeIcons.strokeRoundedCloud);
    } else if (sound == 'forest') {
      environmentIconSound = const Icon(HugeIcons.strokeRoundedPineTree);
    } else if (sound == 'white') {
      environmentIconSound = const Icon(HugeIcons.strokeRoundedVoice);
    } else {
      environmentIconSound = const Icon(HugeIcons.strokeRoundedVolumeMute02);
    }

    final currentTheme = Theme.of(context);
    final primaryColor = currentTheme.colorScheme.primary;

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
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          extendBody: false,
          drawer: const SettingsDrawer(),
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                physics: const PageScrollPhysics(),
                children: _pages,
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 6,
                left: 12,
                child: Opacity(
                  opacity: _iconOpacity,
                  child: IconButton(
                    icon: Image.asset(
                      'assets/icon/Icon_fill.png',
                      width: 28,
                      height: 28,
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 36,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        0,
                        HugeIcons.strokeRoundedTask01,
                        primaryColor,
                      ),
                      _buildNavItem(
                        1,
                        HugeIcons.strokeRoundedClock01,
                        primaryColor,
                      ),
                      _buildNavItem(
                        2,
                        environmentIconSound.icon!,
                        primaryColor,
                      ),
                      _buildNavItem(
                        3,
                        HugeIcons.strokeRoundedBook02,
                        primaryColor,
                      ),
                      _buildNavItem(
                        4,
                        HugeIcons.strokeRoundedBarChart,
                        primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
