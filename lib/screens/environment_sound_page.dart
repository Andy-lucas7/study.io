import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/environment_notifier.dart';
import '../styles.dart';
import '../widgets/settings_drawer.dart';

class WaveAnimation extends StatefulWidget {
  final bool isActive;
  final Widget child;

  const WaveAnimation({super.key, required this.isActive, required this.child});

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return Stack(
      children: [
        CustomPaint(painter: _WavePainter(_controller), child: Container()),
        widget.child,
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final AnimationController controller;

  _WavePainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    const cornerRadius = Radius.circular(20);
    final maxExpand = size.width * 0.08;

    for (int i = 0; i < 3; i++) {
      final progress = (controller.value + i / 3) % 1.0;
      final expand = progress * maxExpand;
      paint.color = const Color.fromARGB(
        180,
        255,
        255,
        255,
      ).withOpacity(1 - progress);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: (size.width - 3) + expand * 2,
          height: (size.height - 3) + expand * 2,
        ),
        cornerRadius,
      );

      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EnvironmentSoundPage extends StatelessWidget {
  const EnvironmentSoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final envNotifier = Provider.of<EnvironmentNotifier>(context);
    final currentEnv = envNotifier.environment;
    final isPlaying = envNotifier.isPlaying;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Som Ambiente',
          style: AppFonts().montserratTitle.copyWith(),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset('assets/icon/Icon_fill.png'),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SettingsDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: Environment.values.map((env) {
            final isSelected = currentEnv == env;
            final showWave = isSelected && isPlaying && env != Environment.mute;

            return GestureDetector(
              onTap: () {
                if (env == currentEnv) {
                  envNotifier.togglePlayPause();
                } else {
                  envNotifier.setEnvironment(env);
                }
              },
              child: WaveAnimation(
                isActive: showWave,
                child: Container(
                  alignment: Alignment.bottomLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected && !showWave
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    image: DecorationImage(
                      image: AssetImage(EnvironmentConfig.getImage(env)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    ),
                    color: AppColors.tile,
                  ),
                  padding: const EdgeInsets.all(16),
                    child: Text(
                      EnvironmentConfig.getLabel(env),
                      style: AppFonts().montserratTitle.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
