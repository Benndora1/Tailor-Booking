import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TailorBookingApp());
}

class TailorBookingApp extends StatelessWidget {
  const TailorBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailor Booking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Set the initial route to LoginScreen
      routes: {
        '/login': (context) => const LoginScreen(), // Route for LoginScreen
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen()
      },
    );
  }
}