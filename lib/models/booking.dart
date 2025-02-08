// models/booking.dart
import 'package:cloud_firestore/cloud_firestore.dart';



class Booking {
  final String id;
  final String tailorId;
  final String userId;
  final DateTime date;
  final String status;

  Booking({
    required this.id,
    required this.tailorId,
    required this.userId,
    required this.date,
    required this.status,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      tailorId: map['tailorId'] ?? '',
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tailorId': tailorId,
      'userId': userId,
      'date': date,
      'status': status,
    };
  }
}