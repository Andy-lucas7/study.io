import 'package:flutter/material.dart';
import '../constants.dart';
import '../home_page.dart';

class SplashPage extends StatefulWidget {
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Offset _tapPosition;
  bool _showAnim = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _circleAnim = Tween(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnim = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset(0, -0.5)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(pageBuilder: (_, __, ___) => HomePage()),
        );
      }
    });
  }

  void _startAnim(Offset pos) {
    _tapPosition = pos;
    setState(() => _showAnim = true);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.inputBackground,
      body: Stack(
        children: [
          HomePage(),
          if (!_showAnim) Container(color: AppColors.inputBackground),
          if (_showAnim)
            AnimatedBuilder(
              animation: _circleAnim,
              builder: (_, __) {
                final r = _circleAnim.value * (size.width + size.height);
                return ClipPath(
                  clipper: HoleClipper(center: _tapPosition, radius: r),
                  child: Container(color: AppColors.inputBackground),
                );
              },
            ),
          if (!_showAnim)
            Center(
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    'Study.io',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
            ),
          if (!_showAnim)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: GestureDetector(
                  onTapDown: (d) => _startAnim(d.globalPosition),
                  child: Icon(Icons.play_circle_fill, color: Colors.white, size: 100),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HoleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  HoleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldReclip(HoleClipper old) =>
      radius != old.radius || center != old.center;
}
