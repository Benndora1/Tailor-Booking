// screens/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BookingScreen extends StatefulWidget {
  final String tailorName;

  const BookingScreen({super.key, required this.tailorName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Future<void> _submitBooking(BuildContext context) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to book')),
        );
        return;
      }

      final date = _dateController.text.trim();
      final service = _serviceController.text.trim();
      final notes = _notesController.text.trim();

      if (date.isEmpty || service.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      // Save booking to Firestore
      await FirebaseFirestore.instance.collection('bookings').add({
        'tailorId': '', // Replace with actual tailor ID
        'userId': userId,
        'date': date,
        'service': service,
        'notes': notes,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking submitted successfully')),
      );

      Navigator.pop(context); // Go back to TailorProfileScreen
    } catch (e) {
      print('Error submitting booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showBookingForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book Appointment with ${widget.tailorName}'), // Use tailorName
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _serviceController,
              decoration: const InputDecoration(labelText: 'Service (e.g., Shirts)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Additional Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitBooking(context),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book with ${widget.tailorName}'), // Use tailorName
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showBookingForm(context),
          child: const Text('Book Now'),
        ),
      ),
    );
  }
}