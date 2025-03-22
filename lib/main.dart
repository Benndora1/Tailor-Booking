import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart' show LoginScreen; // Explicitly import only LoginScreen
import 'screens/register_screen.dart' show RegisterScreen;
import 'screens/home_screen.dart' as home;
import 'screens/tailor_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/booking_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/tailor_profile_screen.dart'; // Import TailorProfileScreen
import 'screens/contact_screen.dart'; // Import Contact/Messaging screen
import 'screens/chats_screen.dart'; // Import Chats list screen

// Import the admin screens
import 'screens/user_management.dart';
import 'screens/tailor_approval.dart';
import 'screens/analytics_screen.dart' as admin;

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Listen to auth state changes
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            // No user is signed in, show LoginScreen
            return const LoginScreen();
          }

          // Fetch user role from Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                // If user document doesn't exist, log them out
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final role = userData['role'] ?? 'user'; // Default to 'user' if 'role' is missing

              // Redirect based on user role
              switch (role) {
                case 'admin':
                  return const AdminDashboard(); // Redirect to Admin Dashboard
                case 'tailor':
                  return const TailorDashboard(); // Redirect to Tailor Dashboard
                default:
                  return const home.HomeScreen(); // Redirect to Home Screen for normal users
              }
            },
          );
        },
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (context) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (context) => const home.HomeScreen());
          case '/tailor-dashboard':
            return MaterialPageRoute(builder: (context) => const TailorDashboard());
          case '/admin-dashboard':
            return MaterialPageRoute(builder: (context) => const AdminDashboard());

        // Admin-specific routes
          case '/admin/users':
            return MaterialPageRoute(builder: (context) => const UserManagementScreen());
          case '/admin/tailor-approval':
            return MaterialPageRoute(builder: (context) => const TailorApprovalScreen());
          case '/admin/analytics':
            return MaterialPageRoute(builder: (context) => const admin.AnalyticsScreen());

        // Bookings routes
          case '/bookings':
          // Show all bookings for the current user (either as customer or tailor)
            return MaterialPageRoute(builder: (context) => const BookingsScreen());

          case '/book-appointment':
          // Route for creating a new booking with a specific tailor
            final tailorId = settings.arguments as String?;
            if (tailorId == null || tailorId.isEmpty) {
              return MaterialPageRoute(builder: (context) => const home.HomeScreen());
            }
            return MaterialPageRoute(
              builder: (context) => BookingScreen(tailorId: tailorId),
            );

          case '/reschedule-booking':
          // Route for rescheduling an existing booking
            final bookingId = settings.arguments as String?;
            if (bookingId == null || bookingId.isEmpty) {
              return MaterialPageRoute(builder: (context) => const BookingsScreen());
            }
            return MaterialPageRoute(
              builder: (context) => BookingScreen(
                bookingId: bookingId,
                isRescheduling: true,
              ),
            );

          case '/tailor-details':
          // Route for viewing a tailor's profile
            final tailorId = settings.arguments as String?;
            if (tailorId == null || tailorId.isEmpty) {
              return MaterialPageRoute(builder: (context) => const home.HomeScreen());
            }
            return MaterialPageRoute(
              builder: (context) => TailorProfileScreen(tailorId: tailorId),
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

          case '/review-booking':
          // Route for reviewing a completed booking
            final bookingId = settings.arguments as String?;
            if (bookingId == null || bookingId.isEmpty) {
              return MaterialPageRoute(builder: (context) => const BookingsScreen());
            }
            // You'll need to create a ReviewScreen component
            // For now, just return to BookingsScreen
            return MaterialPageRoute(builder: (context) => const BookingsScreen());

        // Contact and Messaging routes
          case '/contact-tailor':
          // Route for contacting a tailor
            final tailorId = settings.arguments as String?;
            if (tailorId == null || tailorId.isEmpty) {
              return MaterialPageRoute(builder: (context) => const home.HomeScreen());
            }
            return MaterialPageRoute(
              builder: (context) => ContactScreen(tailorId: tailorId),
            );

          case '/contact-with-booking':
          // Route for contacting about a specific booking
            final args = settings.arguments as Map<String, String>?;
            if (args == null || args['tailorId'] == null) {
              return MaterialPageRoute(builder: (context) => const BookingsScreen());
            }
            return MaterialPageRoute(
              builder: (context) => ContactScreen(
                tailorId: args['tailorId']!,
                bookingId: args['bookingId'],
              ),
            );

          case '/chats':
          // Route for viewing all chats
            return MaterialPageRoute(builder: (context) => const ChatsScreen());

          default:
          // Redirect to HomeScreen for undefined routes
            return MaterialPageRoute(builder: (context) => const home.HomeScreen());
        }
      },
    );
  }
}