// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a tailor profile for a user with tailor role
  Future<void> createTailorProfile(String userId) async {
    // First get the user document
    DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw Exception('User does not exist');
    }

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    // Check if user has tailor role
    if (userData['role'] != 'tailor') {
      throw Exception('User does not have tailor role');
    }

    // Create tailor document using the user's ID
    await _db.collection('tailors').doc(userId).set({
      'name': userData['name'] ?? '',
      'location': '',  // Can be updated later
      'services': [],  // Can be updated later
      'rating': 0.0,   // Initial rating
      'userId': userId // Reference back to user
    });
  }

  // Update tailor profile
  Future<void> updateTailorProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('tailors').doc(userId).update(data);
  }

  // Get all users with tailor role
  Stream<QuerySnapshot> getTailorUsers() {
    return _db.collection('users')
        .where('role', isEqualTo: 'tailor')
        .snapshots();
  }

  // Get tailor profile by user ID
  Future<DocumentSnapshot> getTailorProfile(String userId) {
    return _db.collection('tailors').doc(userId).get();
  }

  // Get all tailor profiles
  Stream<QuerySnapshot> getAllTailorProfiles() {
    return _db.collection('tailors').snapshots();
  }
}

// Example usage:
void initializeTailorProfile() async {
  final service = FirestoreService();

  try {
    // Get all users with tailor role
    service.getTailorUsers().listen((snapshot) {
      for (var doc in snapshot.docs) {
        // Create tailor profile for each tailor user
        service.createTailorProfile(doc.id);
      }
    });
  } catch (e) {
    print('Error initializing tailor profiles: $e');
  }
}

// Update a tailor's profile
void updateProfile(String userId) async {
  final service = FirestoreService();

  await service.updateTailorProfile(userId, {
    'location': 'Downtown',
    'services': ['Alterations', 'Custom Suits'],
  });
}