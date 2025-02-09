import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e.code);
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(String email, String password, String role) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      if (user != null) {
        // Save user data to Firestore with the specified role
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'name': '', // Can be updated later
          'role': role, // Assign the role
          'created_at': FieldValue.serverTimestamp(),
        });
        print('User registered with role: $role');
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e.code);
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if the user exists in Firestore
        final userDoc = await _db.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // If the user doesn't exist, create a new document with default role 'user'
          await _db.collection('users').doc(user.uid).set({
            'email': user.email,
            'name': user.displayName ?? '',
            'role': 'user', // Default role for Google users
            'created_at': FieldValue.serverTimestamp(),
          });
          print('New Google user registered with role: user');
        }
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e.code);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Handle Firebase Auth errors
  User? _handleFirebaseAuthError(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        print('The email address is malformed.');
        break;
      case 'user-disabled':
        print('The user account has been disabled.');
        break;
      case 'user-not-found':
        print('There is no user record corresponding to this identifier.');
        break;
      case 'wrong-password':
        print('The password is invalid or the user does not have a password.');
        break;
      default:
        print('An undefined error occurred: $errorCode');
    }
    return null;
  }

  /// Fetch the user's role from Firestore
  Future<String> getUserRole(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['role'] ?? 'user'; // Default to 'user' if role is missing
      }
      return 'user'; // Default to 'user' if no document exists
    } catch (e) {
      print('Error fetching user role: $e');
      return 'user'; // Default to 'user' on error
    }
  }
}