// screens/admin/user_management.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get the user document from Firestore
        final userDoc = await _db.collection('users').doc(currentUser.uid).get();
        final userData = userDoc.data();

        if (userData != null && userData['role'] == 'admin') {
          setState(() {
            _isAdmin = true;
          });
          print('User is admin: $_isAdmin');
        } else {
          print('User is not admin. Role: ${userData?['role']}');
        }
      } else {
        print('No user is currently logged in');
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                FaIcon(
                  FontAwesomeIcons.usersCog,
                  color: Colors.blue,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'User Roles',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.exclamationTriangle,
                            color: Colors.amber,
                            size: 32,
                          ),
                          const SizedBox(height: 16),
                          Text('Error loading users: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final users = snapshot.data!.docs;

                  if (users.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.userSlash,
                            color: Colors.grey,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text('No users found'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;
                      final email = userData['email'] ?? 'Unknown';
                      // Use name instead of email, falling back to email if name isn't available
                      final name = userData['name'] ?? userData['displayName'] ?? email;
                      final role = userData['role'] ?? 'user';

                      // Choose icon based on role
                      IconData roleIcon;
                      Color roleColor;

                      if (role == 'admin') {
                        roleIcon = FontAwesomeIcons.userShield;
                        roleColor = Colors.purple;
                      } else if (role == 'tailor') {
                        roleIcon = FontAwesomeIcons.cut;
                        roleColor = Colors.green;
                      } else {
                        roleIcon = FontAwesomeIcons.user;
                        roleColor = Colors.blue;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withOpacity(0.2),
                            child: FaIcon(
                              roleIcon,
                              color: roleColor,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            name, // Display name instead of email
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(email, style: TextStyle(fontSize: 12)), // Show email as secondary info
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: roleColor.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: roleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: role == 'user'
                              ? ElevatedButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.award,
                              size: 14,
                            ),
                            label: const Text('Promote'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _promoteToTailor(userId, name),
                          )
                              : role == 'tailor'
                              ? ElevatedButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.levelDown,
                              size: 14,
                            ),
                            label: const Text('Demote'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _demoteToUser(userId, name),
                          )
                              : null,
                          isThreeLine: true,
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

  /// Promote a user to a tailor
  Future<void> _promoteToTailor(String userId, String userName) async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.exclamationTriangle,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 12),
              Text('Only admins can promote users'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create a batch for atomic operations
      final batch = _db.batch();

      // Update the user's role in the users collection
      final userRef = _db.collection('users').doc(userId);
      batch.update(userRef, {'role': 'tailor'});

      // Check if there's already a document in the tailors collection
      final tailorDoc = await _db.collection('tailors').doc(userId).get();

      // If no tailor document exists, create one
      if (!tailorDoc.exists) {
        final userDoc = await userRef.get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          final tailorRef = _db.collection('tailors').doc(userId);
          batch.set(tailorRef, {
            'name': userData['name'] ?? userData['displayName'] ?? userData['email'],
            'email': userData['email'],
            'userId': userId,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.check,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 12),
              Text('$userName promoted to tailor'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error promoting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.exclamationCircle,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 12),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Demote a tailor to a user
  Future<void> _demoteToUser(String userId, String userName) async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.exclamationTriangle,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 12),
              Text('Only admins can demote users'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create a batch for atomic operations
      final batch = _db.batch();

      // Update the user's role in the users collection
      final userRef = _db.collection('users').doc(userId);
      batch.update(userRef, {'role': 'user'});

      // Check if there's a document in the tailors collection and update status
      final tailorRef = _db.collection('tailors').doc(userId);
      final tailorDoc = await tailorRef.get();

      if (tailorDoc.exists) {
        batch.update(tailorRef, {
          'status': 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.check,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 12),
              Text('$userName demoted to user'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error demoting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.exclamationCircle,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 12),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}