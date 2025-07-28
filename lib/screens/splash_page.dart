import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
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


  final List<String> _backgroundImages = [
    'assets/images/forest.png',
    'assets/images/coffee.png',
    'assets/images/rain.png',
  ];

  late String _selectedBackground;
  bool _imagesPrecached = false;

  @override
  void initState() {
    super.initState();

    _selectedBackground = _backgroundImages[Random().nextInt(_backgroundImages.length)];

    _controller = AnimationController(
      duration: Duration(milliseconds: 3500),
      vsync: this,
    );

    _circleAnim = Tween(begin: 0.0, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnim = Tween(begin: 2.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset(0, -1.5)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(pageBuilder: (_, __, ___) => HomePage()),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      for (var image in _backgroundImages) {
        precacheImage(AssetImage(image), context);
      }
      precacheImage(const AssetImage('assets/icon/Icon.png'), context);
      _imagesPrecached = true;
    }
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
      body: Stack(
        children: [
          Image.asset(
            _selectedBackground,
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
          ),
          HomePage(),
          if (!_showAnim)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_selectedBackground),
                  fit: BoxFit.fill,
                ),
              ),
              width: size.width,
              height: size.height,
            ),
          if (_showAnim)
            AnimatedBuilder(
              animation: _circleAnim,
              builder: (_, __) {
                final r = _circleAnim.value * (size.width + size.height);
                return ClipPath(
                  clipper: HoleClipper(center: _tapPosition, radius: r),
                  child: Container(decoration: BoxDecoration(image: DecorationImage(image: AssetImage(_selectedBackground), fit: BoxFit.fill)),));
              },
            ),
          if (!_showAnim)
            SizedBox(
              height: 250,
              width: double.infinity,
              child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                  'Study',
                  style: GoogleFonts.pacifico(
                    color: Colors.white,
                    fontSize: 78,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                  Text(
                  '.io',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 62,
                    fontWeight: FontWeight.w300,
                  ),
                  ),
                ],
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
                  child: Icon(Icons.play_circle_rounded, color: Colors.white, size: 100),
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