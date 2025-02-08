// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tailor.dart';
import '../models/booking.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Tailor>> getTailors() {
    return _db.collection('tailors').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Tailor.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> addBooking(Booking booking) {
    return _db.collection('bookings').add(booking.toMap());
  }

  Stream<List<Booking>> getBookingsForUser(String userId) {
    return _db.collection('bookings').where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    });
  }
}