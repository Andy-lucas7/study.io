import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifiers/environment_notifier.dart';
import 'notifiers/pomodoro_notifier.dart';
import 'notifiers/theme_notifier.dart';
import 'screens/splash_page.dart';
import 'services/database_service.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EnvironmentNotifier()),
        ChangeNotifierProvider(create: (_) => PomodoroNotifier()),
        ChangeNotifierProvider(
          create: (context) => ThemeNotifier(Provider.of<EnvironmentNotifier>(context, listen: false)),
        ),
      ],
      builder: (context, _) {
        final themeNotifier = Provider.of<ThemeNotifier>(context);

        return MaterialApp(
          title: 'Study.io',
          debugShowCheckedModeBanner: false,
          theme: themeNotifier.lightTheme,
          darkTheme: themeNotifier.darkTheme,
          themeMode: themeNotifier.themeMode,
          home: const SplashPage(),
          navigatorObservers: [routeObserver],
        );
      },
    ),
  );
}