import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/environment_notifier.dart';
import '../styles.dart';
import '../widgets/settings_drawer.dart';

class EnvironmentPlayerPage extends StatefulWidget {
  const EnvironmentPlayerPage({super.key});

  @override
  State<EnvironmentPlayerPage> createState() => _EnvironmentPlayerPageState();
}

class _EnvironmentPlayerPageState extends State<EnvironmentPlayerPage> {
  bool isPlaying = true;

  String get backgroundPath {
    final envNotifier = Provider.of<EnvironmentNotifier>(
      context,
      listen: false,
    );
    return envNotifier.backgroundImagePath;
  }

  @override
  Widget build(BuildContext context) {
    final envNotifier = Provider.of<EnvironmentNotifier>(context);
    final backgroundImagePath = context
        .watch<EnvironmentNotifier>()
        .backgroundImagePath;
    final theme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: backgroundImagePath.isNotEmpty
              ? Image.asset(backgroundImagePath, fit: BoxFit.cover)
              : Container(color: AppColors.background),
        ),
        Positioned.fill(
          child: backgroundImagePath.isNotEmpty
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(color: Colors.black.withOpacity(0.75)),
                )
              : Container(color: AppColors.background),
        ),
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Tocando agora:',
              style: AppFonts().montserratTitle.copyWith(fontSize: 20),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          drawer: const SettingsDrawer(),
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  envNotifier.backgroundImagePath,
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 24),
                Text(
                  _getLabel(envNotifier.environment),
                  style: TextStyle(fontSize: 24, color: theme.onPrimary),
                ),
                const SizedBox(height: 16),
                IconButton(
                  iconSize: 64,
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: theme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      isPlaying = !isPlaying;
                    });
                    envNotifier.togglePlayPause(isPlaying);
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    envNotifier.switchEnvironment();
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Próximo'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getLabel(Environment env) {
    return switch (env) {
      Environment.rain => 'Chuva Relaxante',
      Environment.forest => 'Sons da Floresta',
      Environment.coffee => 'Ambiente de Cafeteria',
      _ => '',
    };
  }
}
