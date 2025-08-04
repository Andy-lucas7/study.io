import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';

enum Environment { mute, rain, forest, coffee, white }

class AppConfig {
  static Color background = Color.fromARGB(255, 12, 16, 19);
  static Color tile = Color.fromARGB(65, 117, 117, 117);
  static Color inputBackground = Color.fromARGB(255, 6, 24, 34);
  static Color moodBackground = Color.fromARGB(255, 16, 21, 25);
  static Color text = Colors.white;
  static Color hintText = Colors.white70;
  static Color border = Color.fromARGB(255, 81, 145, 194);
  static Color splashBackground = Colors.black;

  static const List<Environment> environments = Environment.values;
  
  final TextStyle montserratTitle = GoogleFonts.montserrat(
    color: AppConfig.text,
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );
  final TextStyle quicksandTitle = GoogleFonts.quicksand(
    color: text,
    fontSize: 24,
    fontWeight: FontWeight.w300,
  );
  final TextStyle roboto = GoogleFonts.roboto(
    color: text,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  final TextStyle pacifico = GoogleFonts.pacifico(
    color: text,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static final Map<Environment, Map<String, dynamic>> _environmentConfigs = {
    Environment.mute: {
      'label': 'Sem Música',
      'backgroundImage': '',
      'image': 'assets/images/mute.png',
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
      'backgroundImage': 'assets/images/coffee_background.png',
      'image': 'assets/images/coffee.png',
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
      'backgroundImage': 'assets/images/white_background.png',
      'image': 'assets/images/white.png',
      'audio': 'audio/white_noise.mp3',
      'theme': ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 175, 214, 214),
          secondary: Color.fromARGB(255, 133, 166, 165),
          onPrimary: Color.fromARGB(255, 189, 255, 246),
        ),
      ),
    },
  };

  static String getLabel(Environment env) => _environmentConfigs[env]!['label'] as String;
  static String getImage(Environment env) => _environmentConfigs[env]!['image'] as String;
  static String getBackgroundImage(Environment env) => _environmentConfigs[env]!['backgroundImage'] as String;
  static String getAudio(Environment env) => _environmentConfigs[env]!['audio'] as String;
  static ThemeData getTheme(Environment env) => _environmentConfigs[env]!['theme'] as ThemeData;
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
    final path = AppConfig.getAudio(_environment);
    if (path.isNotEmpty) {
      await _player.play(AssetSource(path));
    }
  }

  ThemeData get currentTheme => AppConfig.getTheme(_environment);
  String get backgroundImagePath => AppConfig.getBackgroundImage(_environment);
  String get imagePath => AppConfig.getImage(_environment);
}