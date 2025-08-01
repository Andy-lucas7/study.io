import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum Environment { mute, rain, forest, coffee, white }

class EnvironmentConfig {
  static final Map<Environment, Map<String, dynamic>> _configs = {
    Environment.mute: {
      'label': 'Sem Música',
      'backgroundImage': '',
      'image': '',
      'audio': '',
      'theme': ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 28, 153, 151),
          secondary: Color.fromARGB(255, 10, 68, 67),
          onPrimary: Color.fromARGB(255, 119, 228, 226),
        ),
      ),
    },
    Environment.rain: {
      'label': 'Chuva',
      'backgroundImage': 'assets/images/rain_background.png',
      'image': 'assets/images/rain.png',
      'audio': 'audio/chuva.mp3',
      'theme': ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 93, 128, 170),
          secondary: Color.fromARGB(255, 54, 81, 154),
          onPrimary: Color.fromARGB(255, 169, 202, 255),
        ),
      ),
    },
    Environment.forest: {
      'label': 'Floresta',
      'backgroundImage': 'assets/images/forest_background.png',
      'image': 'assets/images/forest.png',
      'audio': 'audio/floresta.mp3',
      'theme': ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 76, 163, 70),
          secondary: Color.fromARGB(255, 35, 105, 30),
          onPrimary: Color.fromARGB(255, 80, 255, 94),
        ),
      ),
    },
    Environment.coffee: {
      'label': 'Cafeteria',
      'image': 'assets/images/coffee.png',
      'backgroundImage': 'assets/images/coffee_background.png',
      'audio': 'audio/cafeteria.mp3',
      'theme': ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 80, 55, 46),
          secondary: Color.fromARGB(255, 57, 40, 34),
          onPrimary: Color.fromARGB(255, 202, 167, 126),
        ),
      ),
    },
    Environment.white: {
      'label': 'White Noise',
      'image': 'assets/images/white.png',
      'backgroundImage': 'assets/images/white_background.png',
      'audio': 'audio/white_boise.mp3',
      'theme': ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 255, 255, 255),
          secondary: Color.fromARGB(255, 105, 105, 105),
          onPrimary: Color.fromARGB(255, 255, 255, 255),
        ),
      ),
    },
  };

  static String getLabel(Environment env) => _configs[env]!['label'] as String;
  static String getImage(Environment env) => _configs[env]!['image'] as String;
  static String getBackgroundImage(Environment env) => _configs[env]!['backgroundImage'] as String;
  static String getAudio(Environment env) => _configs[env]!['audio'] as String;
  static ThemeData getTheme(Environment env) => _configs[env]!['theme'] as ThemeData;
}

class EnvironmentNotifier extends ChangeNotifier {
  Environment _environment = Environment.mute;
  final _player = AudioPlayer();
  bool _isPlaying = false;

  Environment get environment => _environment;
  bool get isPlaying => _isPlaying;

  EnvironmentNotifier() {
    _player.setReleaseMode(ReleaseMode.loop);
  }

  void setEnvironment(Environment env) async {
    if (_environment != env) {
      _environment = env;
      await _startEnvironment();
      _isPlaying = env != Environment.mute;
      notifyListeners();
    }
  }

  void togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
      _isPlaying = false;
    } else if (_environment != Environment.mute) {
      await _player.resume();
      _isPlaying = true;
    }
    notifyListeners();
  }

  Future<void> _startEnvironment() async {
    await _player.stop();
    final path = EnvironmentConfig.getAudio(_environment);
    if (path.isNotEmpty) {
      await _player.play(AssetSource(path));
    }
  }

  ThemeData get currentTheme => EnvironmentConfig.getTheme(_environment);
  String get backgroundImagePath => EnvironmentConfig.getBackgroundImage(_environment);
  String get imagePath => EnvironmentConfig.getImage(_environment);
}