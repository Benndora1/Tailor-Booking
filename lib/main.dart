// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'screens/login_screen.dart';
// import 'screens/home_screen.dart' as home;
// import 'screens/tailor_dashboard.dart';
// import 'screens/admin_dashboard.dart';
// import 'screens/booking_screen.dart' as bookings;
// import 'screens/edit_profile_screen.dart'; // Import EditProfileScreen
// import 'screens/analytics_screen.dart'; // Import AnalyticsScreen
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const SewCraftApp());
// }
//
// class SewCraftApp extends StatelessWidget {
//   const SewCraftApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SewCraft',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         cardTheme: CardTheme(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ),
//       onGenerateRoute: (settings) {
//         switch (settings.name) {
//           case '/login':
//             return MaterialPageRoute(builder: (context) => const LoginScreen());
//           case '/home':
//             return MaterialPageRoute(builder: (context) => const home.HomeScreen());
//           case '/tailor-dashboard':
//             return MaterialPageRoute(builder: (context) => const TailorDashboard());
//           case '/admin-dashboard':
//             return MaterialPageRoute(builder: (context) => const AdminDashboard());
//           case '/bookings': // Route for BookingsScreen
//             final userId = settings.arguments as String?;
//             if (userId == null || userId.isEmpty) {
//               // Redirect to HomeScreen instead of showing an error page
//               return MaterialPageRoute(builder: (context) => const home.HomeScreen());
//             }
//             return MaterialPageRoute(
//               builder: (context) => bookings.BookingScreen(tailorName: 'Tailor Name'), // Pass userId
//             );
//           case '/edit-profile': // Route for EditProfileScreen
//             final tailorId = settings.arguments as String?;
//             if (tailorId == null || tailorId.isEmpty) {
//               // Redirect to TailorDashboard instead of showing an error page
//               return MaterialPageRoute(builder: (context) => const TailorDashboard());
//             }
//             return MaterialPageRoute(
//               builder: (context) => EditProfileScreen(tailorId: tailorId), // Pass tailorId
//             );
//           case '/analytics': // Route for AnalyticsScreen
//             return MaterialPageRoute(
//               builder: (context) => const AnalyticsScreen(),
//             );
//           default:
//           // Redirect to HomeScreen for undefined routes
//             return MaterialPageRoute(builder: (context) => const home.HomeScreen());
//         }
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart' as home;
import 'screens/tailor_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/booking_screen.dart' as bookings;
import 'screens/edit_profile_screen.dart'; // Import EditProfileScreen
import 'screens/analytics_screen.dart'; // Import AnalyticsScreen

// Import the new admin screens
import 'screens/user_management.dart';
import 'screens/tailor_approval.dart';
import 'screens/analytics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SewCraftApp());
}

class SewCraftApp extends StatelessWidget {
  const SewCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SewCraft',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (context) => const home.HomeScreen());
          case '/tailor-dashboard':
            return MaterialPageRoute(builder: (context) => const TailorDashboard());

        // Admin routes
          case '/admin-dashboard':
            return MaterialPageRoute(builder: (context) => const AdminDashboard());
          case '/admin/users':
            return MaterialPageRoute(builder: (context) => const UserManagementScreen());
          case '/admin/tailor-approval':
            return MaterialPageRoute(builder: (context) => const TailorApprovalScreen());
          case '/admin/analytics':
            return MaterialPageRoute(builder: (context) => const AnalyticsScreen());

          case '/bookings': // Route for BookingsScreen
            final userId = settings.arguments as String?;
            if (userId == null || userId.isEmpty) {
              // Redirect to HomeScreen instead of showing an error page
              return MaterialPageRoute(builder: (context) => const home.HomeScreen());
            }
            return MaterialPageRoute(
              builder: (context) => bookings.BookingScreen(tailorName: 'Tailor Name'), // Pass userId
            );
          case '/edit-profile': // Route for EditProfileScreen
            final tailorId = settings.arguments as String?;
            if (tailorId == null || tailorId.isEmpty) {
              // Redirect to TailorDashboard instead of showing an error page
              return MaterialPageRoute(builder: (context) => const TailorDashboard());
            }
            return MaterialPageRoute(
              builder: (context) => EditProfileScreen(tailorId: tailorId), // Pass tailorId
            );
          case '/analytics': // Route for AnalyticsScreen
            return MaterialPageRoute(
              builder: (context) => const AnalyticsScreen(),
            );
          default:
          // Redirect to HomeScreen for undefined routes
            return MaterialPageRoute(builder: (context) => const home.HomeScreen());
        }
      },
    );
  }
}