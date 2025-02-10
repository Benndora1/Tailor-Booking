// add_tailors.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  await Firebase.initializeApp();

  final db = FirebaseFirestore.instance;
  final tailors = [
    {
      'name': 'John Smith',
      'email': 'john.smith@example.com',
      'role': 'tailor',
      'location': 'Downtown, New York',
      'services': ['Suits', 'Alterations', 'Custom Clothing'],
      'experience': '15 years',
      'rating': 4.8,
      'status': 'approved'
    },
    {
      'name': 'Maria Garcia',
      'email': 'maria.garcia@example.com',
      'role': 'tailor',
      'location': 'Brooklyn, New York',
      'services': ['Wedding Dresses', 'Evening Wear', 'Alterations'],
      'experience': '12 years',
      'rating': 4.9,
      'status': 'approved'
    }
  ];

  for (final tailor in tailors) {
    try {
      await db.collection('users').add(tailor);
      print('Added tailor: ${tailor['name']}');
    } catch (e) {
      print('Error adding tailor ${tailor['name']}: $e');
    }
  }
}