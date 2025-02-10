// screens/tailor_dashboard.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import Font Awesome
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth


class TailorDashboard extends StatelessWidget {
  const TailorDashboard({super.key});

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': status,
      });
      print('Booking status updated to $status');
    } catch (e) {
      print('Error updating booking status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor Dashboard'),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.signOutAlt), // Font Awesome sign-out-alt icon
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Bookings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('tailorId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text('Error loading bookings'));
                  }

                  final bookings = snapshot.data!.docs;
                  if (bookings.isEmpty) {
                    return const Center(child: Text('No bookings yet'));
                  }

                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final bookingData = bookings[index].data() as Map<String, dynamic>;
                      final bookingId = bookings[index].id;
                      final userId = bookingData['userId'] ?? 'Unknown';
                      final date = bookingData['date'] ?? 'Unknown';
                      final service = bookingData['service'] ?? 'Unknown';
                      final status = bookingData['status'] ?? 'pending';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const FaIcon(FontAwesomeIcons.calendarCheck, color: Colors.green), // Font Awesome calendar-check icon
                          title: Text('User ID: $userId'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: $date'),
                              Text('Service: $service'),
                              Text('Status: $status'),
                            ],
                          ),
                          trailing: status == 'pending'
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.checkCircle, color: Colors.green), // Accept icon
                                onPressed: () => _updateBookingStatus(bookingId, 'accepted'),
                              ),
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.timesCircle, color: Colors.red), // Reject icon
                                onPressed: () => _updateBookingStatus(bookingId, 'rejected'),
                              ),
                            ],
                          )
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}