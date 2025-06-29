import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/theme_notifier.dart';
import '../notifiers/environment_notifier.dart';

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
        drawerBackground = 'assets/images/rain.jpg';
        break;
      case Environment.forest:
        drawerBackground = 'assets/images/forest.jpg';
        break;
      case Environment.coffee:
        drawerBackground = 'assets/images/coffee.jpg';
        break;
      case Environment.mute:
        drawerBackground = null;
        break;
    }

    return Drawer(
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 1, 20, 31)
          : const Color.fromARGB(255, 255, 255, 255),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: currentTheme.colorScheme.primary,
              image: drawerBackground != null
                  ? DecorationImage(
                      image: AssetImage(drawerBackground),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: const Text(
              'Configurações',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          SwitchListTile(
            title: Text(
              'Tema Escuro',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            secondary: Icon(
              Icons.brightness_6,
              color: isDarkMode ? Colors.white : Colors.grey[600],
            ),
            value: isDarkMode,
            onChanged: (_) => themeNotifier.toggleTheme(),
            inactiveThumbColor: const Color.fromARGB(255, 116, 116, 116),
            inactiveTrackColor: const Color.fromARGB(255, 255, 255, 255),
            trackOutlineColor: WidgetStateProperty.all(
              isDarkMode
                  ? const Color.fromARGB(255, 5, 0, 0)
                  : const Color.fromARGB(255, 116, 116, 116),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.info,
              color: isDarkMode ? Colors.white : Colors.grey[600],
            ),
            title: Text(
              'Sobre o App',
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
