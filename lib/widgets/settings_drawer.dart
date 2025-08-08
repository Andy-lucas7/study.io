import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_io/screens/splash_page.dart';
import '../core/app_config.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/about_page.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final imagePath = context
        .watch<EnvironmentNotifier>()
        .imagePath;

    Future<void> goToAboutPage() async {
      MaterialPageRoute(builder: (_) => const AboutPage());
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AboutPage()),
      );
    }

    Future<void> goToSplashPage() async {
      MaterialPageRoute(builder: (_) => const SplashPage());
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SplashPage()),
      );
    }

    return Drawer(
      backgroundColor: AppConfig.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: (imagePath != 'assets/images/mute.png' && imagePath.isNotEmpty)
                    ? AssetImage(imagePath)
                    : AssetImage('assets/icon/banner.png'),
                    
                fit: BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [ Color.fromARGB(0, 0, 0, 0), AppConfig.background],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Study',
                          style: GoogleFonts.pacifico(
                            color: Colors.white,
                            fontSize: 50,
                          ),
                        ),
                        Text(
                          '.io',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            onTap: goToAboutPage,
            leading: Icon(HugeIcons.strokeRoundedInformationCircle, color: Colors.white),
            title: Text(
              'Sobre o Study.io',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ListTile(
            onTap: goToSplashPage,
            leading: Icon(HugeIcons.strokeRoundedLogout01, color: Colors.white),
            title: Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
