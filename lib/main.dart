import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifiers/pomodoro_notifier.dart';
import 'screens/splash_page.dart';
import 'core/app_config.dart';
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final environmentTheme = context.watch<EnvironmentNotifier>().currentTheme;

    return MaterialApp(
      title: 'Study.io',
      debugShowCheckedModeBanner: false,
      theme: environmentTheme,
      home: const SplashPage(),
      navigatorObservers: [routeObserver],
    );
  }
}
