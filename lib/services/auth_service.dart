import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // Create a new user with email and password
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e.code);
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the User
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
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
      await _googleSignIn.signOut(); // Sign out from Google as well
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
}