import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../core/app_config.dart';
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
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 2; i++) {
      final p = (controller.value + (i * 0.5)) % 1.0;
      final curvedP = Curves.easeOut.transform(p);
      final expand = curvedP * 12.0;

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.5 * (1 - p))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * (1 - p) + 1.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: size.width + expand * 2,
          height: size.height + expand * 2,
        ),
        Radius.circular(20 + expand * 0.5),
      );

      canvas.drawRRect(rrect, paint);
    }

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(
        0.2 + 0.3 * math.sin(controller.value * 2 * math.pi).abs(),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrectBase = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(rrectBase, borderPaint);
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(12),
          child: Container(),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Som Ambiente',
          style: AppConfig().montserratTitle.copyWith(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      alignment: Alignment.bottomLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border:
                            isSelected && !isPlaying && env != Environment.mute
                            ? Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5,
                              )
                            : null,
                        image: DecorationImage(
                          image: AssetImage(AppConfig.getImage(env)),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.4),
                            BlendMode.darken,
                          ),
                        ),
                        color: AppConfig.tile,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        AppConfig.getLabel(env),
                        style: AppConfig().montserratTitle.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ),
                    Center(
                      child: AnimatedScale(
                        scale:
                            (isSelected &&
                                !isPlaying &&
                                env != Environment.mute)
                            ? 1.0
                            : 0.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity:
                              (isSelected &&
                                  !isPlaying &&
                                  env != Environment.mute)
                              ? 1.0
                              : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.pause_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
