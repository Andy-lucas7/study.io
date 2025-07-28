import 'package:flutter/material.dart';
import 'environment_notifier.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  late final EnvironmentNotifier _environmentNotifier;

  ThemeNotifier(this._environmentNotifier) {
    _environmentNotifier.addListener(_updateThemes); // Atualiza temas quando o ambiente muda
  }

  ThemeMode get themeMode => _themeMode;

  ThemeData get lightTheme {
    return _environmentNotifier.currentTheme.copyWith(
      brightness: Brightness.light,
      // Ajuste de cores para modo claro, se necessário
      scaffoldBackgroundColor: _environmentNotifier.currentTheme.scaffoldBackgroundColor.computeLuminance() > 0.5
          ? Colors.grey[300]
          : Colors.white,
      colorScheme: _environmentNotifier.currentTheme.colorScheme.copyWith(brightness: Brightness.light),
      appBarTheme: AppBarTheme(
        color: const Color.fromARGB(255, 169, 169, 169),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  ThemeData get darkTheme {
    return _environmentNotifier.currentTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color.fromRGBO(6, 24, 34, 1),
      colorScheme: _environmentNotifier.currentTheme.colorScheme.copyWith(brightness: Brightness.dark),
      appBarTheme: AppBarTheme(
        color: Colors.black,
      ),
    );
  }

  void _updateThemes() {
    notifyListeners(); // Reconstrói a UI quando o ambiente muda
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}