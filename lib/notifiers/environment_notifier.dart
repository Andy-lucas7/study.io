import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum Environment { mute, rain, forest, coffee }

class EnvironmentNotifier extends ChangeNotifier {
  Environment _environment = Environment.mute;
  final _player = AudioPlayer();

  Environment get environment => _environment;

  EnvironmentNotifier() {
    _startEnvironment();
  }

  void switchEnvironment() {
    _environment = Environment.values[
      (_environment.index + 1) % Environment.values.length
    ];
    _startEnvironment();
    notifyListeners();
  }

  Future<void> _startEnvironment() async {
    String path = switch (_environment) {
      Environment.mute => '',
      Environment.rain => 'audio/chuva.mp3',
      Environment.forest => 'audio/floresta.mp3',
      Environment.coffee => 'audio/cafeteria.mp3',
    };

    await _player.stop();
    if (path.isNotEmpty) {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(path));
    }
  }

  ThemeData get currentTheme {
    switch (_environment) {
      case Environment.mute:
        return ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: Color.fromARGB(255, 28, 153, 151), secondary: Color.fromARGB(255, 10, 68, 67), onPrimary: Color.fromARGB(255, 119, 228, 226)),
        );
      case Environment.rain:
        return ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color.fromARGB(255, 93, 128, 170), secondary: Color.fromARGB(255, 54, 81, 154), onPrimary: Color.fromARGB(255, 169, 202, 255)),
        );
      case Environment.forest:
        return ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color.fromARGB(255, 76, 163, 70), secondary: Color.fromARGB(255, 35, 105, 30), onPrimary: Color.fromARGB(255, 80, 255, 94)),
        );
      case Environment.coffee:
        return ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color.fromARGB(255, 80, 55, 46), secondary: Color.fromARGB(255, 57, 40, 34), onPrimary: Color.fromARGB(255, 202, 167, 126)),
        );
    }
  }

  String get backgroundImagePath {
    switch (_environment) {
      case Environment.rain:
        return 'assets/images/rain.png';
      case Environment.forest:
        return 'assets/images/forest.png';
      case Environment.coffee:
        return 'assets/images/coffee.png';
      case Environment.mute:
        return '';
    }
  }
}