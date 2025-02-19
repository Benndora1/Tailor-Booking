// screens/tailor_dashboard.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TailorDashboard extends StatelessWidget {
  const TailorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('You must be logged in as a tailor')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SewCraft Tailor Dashboard'),
      ),
      drawer: _buildDrawer(context, user.uid), // Add the drawer
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
                stream: _getBookings(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.circleExclamation,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error ?? 'No bookings found'}'),
                        ],
                      ),
                    );
                  }

                  final bookings = snapshot.data!.docs;
                  if (bookings.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.hourglassEmpty,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text('No bookings yet'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final bookingData = bookings[index].data() as Map<String, dynamic>;
                      final userId = bookingData['userId'] ?? 'Unknown';
                      final date = bookingData['date'] ?? 'No date';
                      final service = bookingData['service'] ?? 'No service';
                      final status = bookingData['status'] ?? 'pending';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: FaIcon(
                            status == 'pending'
                                ? FontAwesomeIcons.hourglass
                                : status == 'accepted'
                                ? FontAwesomeIcons.checkCircle
                                : status == 'rejected'
                                ? FontAwesomeIcons.timesCircle
                                : FontAwesomeIcons.solidStar,
                            color: status == 'pending'
                                ? Colors.orange
                                : status == 'accepted'
                                ? Colors.green
                                : status == 'rejected'
                                ? Colors.red
                                : Colors.amber,
                          ),
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
                                icon: const FaIcon(FontAwesomeIcons.checkCircle, color: Colors.green),
                                onPressed: () => _updateBookingStatus(bookings[index].id, 'accepted'),
                                tooltip: 'Accept Booking',
                              ),
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.timesCircle, color: Colors.red),
                                onPressed: () => _updateBookingStatus(bookings[index].id, 'rejected'),
                                tooltip: 'Reject Booking',
                              ),
                            ],
                          )
                              : status == 'accepted'
                              ? IconButton(
                            icon: const FaIcon(FontAwesomeIcons.solidStar, color: Colors.amber),
                            onPressed: () => _updateBookingStatus(bookings[index].id, 'completed'),
                            tooltip: 'Mark as Completed',
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

  /// Build the drawer for navigation
  Drawer _buildDrawer(BuildContext context, String tailorId) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FaIcon(
                  FontAwesomeIcons.userTie,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(tailorId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Text('Tailor not found');
                    }
                    final tailorData = snapshot.data!.data() as Map<String, dynamic>;
                    return Text(
                      'Welcome, ${tailorData['name'] ?? 'Tailor'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.list),
            title: const Text('My Bookings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushReplacementNamed(context, '/tailor-dashboard'); // Navigate to bookings
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.pen),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/edit-profile', arguments: tailorId); // Navigate to edit profile
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.chartBar),
            title: const Text('View Analytics'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/analytics'); // Navigate to analytics
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.rightFromBracket),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context); // Close the drawer
              await FirebaseAuth.instance.signOut(); // Sign out the tailor
              Navigator.pushReplacementNamed(context, '/login'); // Redirect to login screen
            },
          ),
        ],
      ),
    );
  }

  /// Fetch bookings for the specified tailorId
  Stream<QuerySnapshot> _getBookings(String tailorId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('tailorId', isEqualTo: tailorId)
        .snapshots();
  }

  /// Update booking status in Firestore
  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': newStatus,
      });
      print('Booking status updated to $newStatus');
    } catch (e) {
      print('Error updating booking status: $e');
    }
  }
}