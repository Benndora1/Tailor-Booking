// screens/tailor_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import Font Awesome
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth


class TailorDetailsScreen extends StatefulWidget {
  final String tailorId;

  const TailorDetailsScreen({super.key, required this.tailorId});

  @override
  State<TailorDetailsScreen> createState() => _TailorDetailsScreenState();
}

class _TailorDetailsScreenState extends State<TailorDetailsScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Future<void> _bookAppointment(BuildContext context) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to book an appointment')),
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
        'tailorId': widget.tailorId,
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

      Navigator.pop(context); // Go back to HomeScreen
    } catch (e) {
      print('Error booking appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showBookingForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Date (YYYY-MM-DD)',
                prefixIcon: const FaIcon(FontAwesomeIcons.calendar), // Font Awesome calendar icon
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _serviceController,
              decoration: InputDecoration(
                labelText: 'Service (e.g., Shirts)',
                prefixIcon: const FaIcon(FontAwesomeIcons.scissors), // Font Awesome scissors icon
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                prefixIcon: const FaIcon(FontAwesomeIcons.pen), // Font Awesome pen icon
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _bookAppointment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const FaIcon(FontAwesomeIcons.check), // Font Awesome check icon
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor Details'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft), // Font Awesome back arrow
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('tailors').doc(widget.tailorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Tailor not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'Unknown';
          final location = data['location'] ?? 'No location';
          final services = List<String>.from(data['services'] ?? []);
          final rating = data['rating']?.toDouble() ?? 0.0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.userTie, size: 48, color: Colors.blue), // Font Awesome tailor icon
                    const SizedBox(width: 16),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.mapMarker, color: Colors.red), // Font Awesome location icon
                    const SizedBox(width: 8),
                    Text('Location: $location'),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: services
                      .map((service) => Chip(
                    avatar: const FaIcon(FontAwesomeIcons.tag, size: 12), // Font Awesome tag icon
                    label: Text(service),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.star, color: Colors.amber), // Font Awesome star icon
                    const SizedBox(width: 8),
                    Text('Rating: $rating/5'),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showBookingForm(context),
                  icon: const FaIcon(FontAwesomeIcons.book, color: Colors.white), // Font Awesome book icon
                  label: const Text('Book Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}