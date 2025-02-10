import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut(); // Sign out the admin
              Navigator.pushReplacementNamed(context, '/login'); // Redirect to login screen
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
              'User Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('users').snapshots(), // Fetch all users
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text('Error loading users'));
                  }

                  final users = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;
                      final email = userData['email'] ?? 'Unknown';
                      final role = userData['role'] ?? 'user';

                      return ListTile(
                        title: Text(email),
                        subtitle: Text('Role: $role'),
                        trailing: role == 'user'
                            ? ElevatedButton(
                          onPressed: () => _promoteToTailor(userId),
                          child: const Text('Promote to Tailor'),
                        )
                            : role == 'tailor'
                            ? ElevatedButton(
                          onPressed: () => _demoteToUser(userId),
                          child: const Text('Demote to User'),
                        )
                            : null,
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

  Future<void> _promoteToTailor(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'role': 'tailor', // Update the role to 'tailor'
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User promoted to tailor')),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have permission to perform this action')),
        );
      } else {
        print('Error promoting user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      print('Error promoting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Demote a tailor to a user
  Future<void> _demoteToUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'role': 'user', // Update the role to 'user'
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tailor demoted to user')),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have permission to perform this action')),
        );
      } else {
        print('Error demoting user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      print('Error demoting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}