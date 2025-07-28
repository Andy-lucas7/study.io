import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/environment_notifier.dart';
import '../notifiers/theme_notifier.dart';
import '../widgets/settings_drawer.dart';

class EnvironmentSoundPage extends StatefulWidget {
  const EnvironmentSoundPage({super.key});

  @override
  State<EnvironmentSoundPage> createState() => _EnvironmentSoundPageState();
}

class _EnvironmentSoundPageState extends State<EnvironmentSoundPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  Offset _tapPosition = Offset.zero;
  String? _oldImagePath;
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _radiusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showAnimation = false;
          _oldImagePath = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation(Offset position) {
    if (_controller.isAnimating) return;

    final env = context.read<EnvironmentNotifier>();
    setState(() {
      _tapPosition = position;
      _oldImagePath = env.backgroundImagePath;
      _showAnimation = true;
    });

    env.switchEnvironment();
    _controller.forward(from: 0.0);
  }

  Widget _buildVinhetaBackground(String path) {
      final themeNotifier = context.read<ThemeNotifier>();
    return Container(
      decoration: BoxDecoration(color: themeNotifier.darkTheme.scaffoldBackgroundColor),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => RadialGradient(
          center: Alignment.center,
          radius: 0.9, // ⬅️ aumenta ou diminui o raio da vinheta
          colors: [
            Colors.white,
            Colors.transparent,
          ],
          stops: const [0.4, 5.0], // ⬅️ muda onde começa e termina o fade
        ).createShader(bounds),
        child: path.isNotEmpty
            ? Image.asset(
                path,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentNotifier>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final currentTheme = themeNotifier.themeMode == ThemeMode.light
        ? themeNotifier.lightTheme
        : themeNotifier.darkTheme;

    final newImagePath = env.backgroundImagePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Som Ambiente'),
        backgroundColor: themeNotifier.themeMode == ThemeMode.light
            ? currentTheme.colorScheme.primary
            : const Color.fromARGB(255, 4, 10, 14),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SettingsDrawer(),
      body: Stack(
        children: [
          _buildVinhetaBackground(newImagePath),
          if (_showAnimation && _oldImagePath != null)
            AnimatedBuilder(
              animation: _radiusAnimation,
              builder: (_, __) {
                final size = MediaQuery.of(context).size;
                final radius =
                    _radiusAnimation.value * (size.width + size.height);
                return ClipPath(
                  clipper: CircularHoleClipper(
                    center: _tapPosition,
                    radius: radius,
                  ),
                  child: _buildVinhetaBackground(_oldImagePath!),
                );
              },
            ),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _startAnimation(details.globalPosition),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(68, 255, 255, 255),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                () {
                  if (env.environment == Environment.mute) {
                    return 'Som ambiente desligado...';
                  } else if (env.environment == Environment.forest) {
                    return 'Tocando som de floresta...';
                  } else if (env.environment == Environment.coffee) {
                    return 'Tocando som de cafeteria...';
                  } else if (env.environment == Environment.rain) {
                    return 'Tocando som de chuva...';
                  } else {
                    return 'Tocando som de ${env.environment}...';
                  }
                }(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularHoleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const CircularHoleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    return Path.combine(PathOperation.difference, full, hole);
  }

  @override
  bool shouldReclip(CircularHoleClipper old) =>
      radius != old.radius || center != old.center;
}
