import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_io/styles.dart';
import '../notifiers/theme_notifier.dart';
import '../notifiers/environment_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/about_page.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final env = context.watch<EnvironmentNotifier>();

    final currentTheme = themeNotifier.themeMode == ThemeMode.light
        ? themeNotifier.lightTheme
        : themeNotifier.darkTheme;

    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    // Define a imagem de fundo com base no ambiente
    String? drawerBackground;
    switch (env.environment) {
      case Environment.rain:
        drawerBackground = 'assets/images/rain.png';
        break;
      case Environment.forest:
        drawerBackground = 'assets/images/forest.png';
        break;
      case Environment.coffee:
        drawerBackground = 'assets/images/coffee.png';
        break;
      case Environment.mute:
        drawerBackground = 'assets/icon/banner.png';
      case Environment.white:
        drawerBackground = 'assets/images/white.png';
        break;
    }

    Future<void> _goToAboutPage() async {
      MaterialPageRoute(builder: (_) => const AboutPage());
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AboutPage()),
      );
    }

    return Drawer(
      backgroundColor: isDarkMode
          ? AppColors.background
          : const Color.fromARGB(255, 255, 255, 255),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(drawerBackground),
                fit: BoxFit.cover,
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
                        colors: [Colors.transparent, AppColors.background],
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
            onTap: _goToAboutPage,
            leading: Icon(
              Icons.info,
              color: isDarkMode ? Colors.white : Colors.grey[600],
            ),
            title: Text(
              'Sobre o Study.io',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: isDarkMode ? Colors.white : Colors.grey[600],
            ),
            title: Text(
              'Sair',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
