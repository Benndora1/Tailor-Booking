import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart' ;
import 'screens/admin_dashboard.dart';
import 'screens/tailor_dashboard.dart';
import 'screens/tailor_details_screen.dart' as details;

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
        // Add some visual improvements
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (context) => const RegisterScreen(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );
          case '/admin-dashboard':
            return MaterialPageRoute(
              builder: (context) => const AdminDashboard(),
            );
          case '/tailor-dashboard':
            return MaterialPageRoute(
              builder: (context) => const TailorDashboard(),
            );
          case '/tailor-details':
          // Handle the tailor details route with arguments
            final tailorId = settings.arguments as String?;
            if (tailorId == null || tailorId.isEmpty) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: const Center(
                    child: Text('Invalid tailor ID'),
                  ),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => details.TailorDetailsScreen(tailorId: tailorId),
            );
          default:
          // Handle unknown routes
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text('Page not found'),
                ),
              ),
            );
        }
      },
    );
  }
}