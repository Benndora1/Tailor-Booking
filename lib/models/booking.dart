// models/booking.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String tailorId; // Reference to the tailor
  final String userId; // Reference to the user
  final String date;
  final String service;
  final String notes;
  final String status; // 'pending', 'accepted', 'rejected', 'completed'
  final Timestamp createdAt;

  Booking({
    required this.id,
    required this.tailorId,
    required this.userId,
    required this.date,
    required this.service,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      tailorId: map['tailorId'] ?? '',
      userId: map['userId'] ?? '',
      date: map['date'] ?? '',
      service: map['service'] ?? '',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] as Timestamp ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tailorId': tailorId,
      'userId': userId,
      'date': date,
      'service': service,
      'notes': notes,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}