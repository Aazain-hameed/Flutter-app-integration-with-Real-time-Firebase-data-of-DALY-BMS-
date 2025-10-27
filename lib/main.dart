import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// screens
import 'screens/login_screen.dart';
import 'screens/home_page.dart';
import 'screens/dashboard.dart';
import 'screens/chart.dart';
import 'screens/logs_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BMS Project',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/dashboard': (context) => const Dashboard(),
        '/logs': (context) => const LogsPage(),
        '/charts': (context) => ChartsPage(), // ✅ Removed 'const'
      },
    );
  }
}
