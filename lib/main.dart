import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'hub/hub_home.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await AppSettings.instance.load();
  runApp(const ClassicGamesHubApp());
}

class ClassicGamesHubApp extends StatelessWidget {
  const ClassicGamesHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classic Games Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HubHome(),
    );
  }
}
