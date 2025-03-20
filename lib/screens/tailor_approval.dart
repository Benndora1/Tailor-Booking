// screens/admin/tailor_approval.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TailorApprovalScreen extends StatefulWidget {
  const TailorApprovalScreen({super.key});

  @override
  State<TailorApprovalScreen> createState() => _TailorApprovalScreenState();
}

class _TailorApprovalScreenState extends State<TailorApprovalScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor Approval'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Approval Requests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('tailors')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text('Error loading requests'));
                  }

                  final tailors = snapshot.data!.docs;

                  if (tailors.isEmpty) {
                    return const Center(
                      child: Text('No pending approval requests'),
                    );
                  }

                  return ListView.builder(
                    itemCount: tailors.length,
                    itemBuilder: (context, index) {
                      final tailorData = tailors[index].data() as Map<String, dynamic>;
                      final tailorId = tailors[index].id;
                      final name = tailorData['name'] ?? 'Unknown';
                      final email = tailorData['email'] ?? 'Unknown';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Email: $email'),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _rejectTailor(tailorId),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () => _approveTailor(tailorId),
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  Future<void> _approveTailor(String tailorId) async {
    try {
      await _db.collection('tailors').doc(tailorId).update({
        'status': 'approved',
      });

      // Also update the user role if needed
      final tailorDoc = await _db.collection('tailors').doc(tailorId).get();
      final userId = tailorDoc.data()?['userId'];
      if (userId != null) {
        await _db.collection('users').doc(userId).update({
          'role': 'tailor',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tailor approved successfully')),
      );
    } catch (e) {
      print('Error approving tailor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectTailor(String tailorId) async {
    try {
      await _db.collection('tailors').doc(tailorId).update({
        'status': 'rejected',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tailor application rejected')),
      );
    } catch (e) {
      print('Error rejecting tailor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}