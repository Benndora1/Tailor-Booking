// services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Register with email and password
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
    required String name,
    String? phone,
    String? bio,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;

      if (user != null) {
        // Create user record in Firestore
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'name': name,
          'role': role == 'tailor' ? 'user' : role, // Tailors start as regular users until approved
          'createdAt': FieldValue.serverTimestamp(),
          'phone': phone ?? '',
        });

        // If registering as a tailor, create a tailor record with pending status
        if (role == 'tailor') {
          await _db.collection('tailors').doc(user.uid).set({
            'userId': user.uid,
            'email': email,
            'name': name,
            'phone': phone ?? '',
            'bio': bio ?? '',
            'status': 'pending', // Start with pending status
            'specialties': [],
            'address': '',
            'rating': 0,
            'reviewCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;

      if (user != null) {
        // Get user data from Firestore
        final userDoc = await _db.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'User data not found in database.',
          );
        }

        final userData = userDoc.data()!;
        final role = userData['role'] as String? ?? 'user';

        // If user is a tailor, check tailor status
        if (role == 'tailor') {
          final tailorDoc = await _db.collection('tailors').doc(user.uid).get();

          if (tailorDoc.exists) {
            final tailorData = tailorDoc.data()!;
            final tailorStatus = tailorData['status'] as String? ?? 'pending';

            return {
              'user': user,
              'role': role,
              'tailorStatus': tailorStatus,
            };
          }
        }

        return {
          'user': user,
          'role': role,
          'tailorStatus': null,
        };
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for this email.',
        );
      }
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in process
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        // Check if user already exists in Firestore
        final userDoc = await _db.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // Create new user record if this is first sign-in
          await _db.collection('users').doc(user.uid).set({
            'email': user.email,
            'name': user.displayName,
            'role': 'user', // Default role for Google sign-in
            'createdAt': FieldValue.serverTimestamp(),
            'photoURL': user.photoURL,
          });
        }
      }

      return user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user role from Firestore
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return (doc.data()?['role'] as String?) ?? 'user';
    } catch (e) {
      print('Error getting user role: $e');
      return 'user'; // Default to user role if there's an error
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      return userDoc.data()?['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}