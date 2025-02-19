import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<QuerySnapshot> _getTailors() {
    return FirebaseFirestore.instance
        .collection('users') // Fetch from users collection
        .where('role', isEqualTo: 'tailor') // Filter for tailors
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.shirt, size: 24),
            SizedBox(width: 12),
            Text('Available Tailors'),
          ],
        ),
        actions: const [
          // IconButton(
          //   icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
          //   onPressed: () async {
          //     await FirebaseAuth.instance.signOut(); // Sign out the user
          //     Navigator.pushReplacementNamed(context, '/login'); // Redirect to login screen
          //   },
          // ),
        ],
      ),
      drawer: _buildDrawer(), // Add a drawer
      body: StreamBuilder<QuerySnapshot>(
        stream: _getTailors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Firestore Error: ${snapshot.error}');
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
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }
          final tailors = snapshot.data?.docs ?? [];
          if (tailors.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.userSlash,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('No tailors available'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tailors.length,
            itemBuilder: (context, index) {
              final tailor = tailors[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const FaIcon(
                      FontAwesomeIcons.userTie,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    tailor['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.locationDot,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(tailor['location'] ?? 'No location'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (tailor['services'] != null) ...[
                        Wrap(
                          spacing: 8,
                          children: (tailor['services'] as List<dynamic>)
                              .map((service) => Chip(
                            label: Text(
                              service.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                  trailing: const FaIcon(FontAwesomeIcons.angleRight),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/tailor-details',
                      arguments: tailors[index].id,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Build the drawer for navigation
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.shirt,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(width: 16),
                Text(
                  'SewCraftApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushReplacementNamed(context, '/home'); // Navigate to HomeScreen
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.list),
            title: const Text('My Bookings'), // Optional: Add a bookings page
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/bookings');
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.rightFromBracket),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut(); // Sign out the user
              Navigator.pushReplacementNamed(context, '/login'); // Redirect to login screen
            },
          ),
        ],
      ),
    );
  }
}