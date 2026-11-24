import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReviveLauncherApp());
}

class ReviveLauncherApp extends StatelessWidget {
  const ReviveLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF8B2CFF);
    return MaterialApp(
      title: 'Revive Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070610),
        colorScheme: ColorScheme.fromSeed(
          seedColor: violet,
          brightness: Brightness.dark,
          surface: const Color(0xFF121020),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
