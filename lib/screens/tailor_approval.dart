// screens/admin/tailor_approval.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TailorApprovalScreen extends StatefulWidget {
  const TailorApprovalScreen({super.key});

  @override
  State<TailorApprovalScreen> createState() => _TailorApprovalScreenState();
}

class _TailorApprovalScreenState extends State<TailorApprovalScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor Management'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: FaIcon(FontAwesomeIcons.hourglassHalf),
              text: 'Pending',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.check),
              text: 'Approved',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.ban),
              text: 'Rejected',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Tailors
          _buildTailorsList('pending', true),

          // Approved Tailors
          _buildTailorsList('approved', false),

          // Rejected Tailors
          _buildTailorsList('rejected', false),
        ],
      ),
    );
  }

  Widget _buildTailorsList(String status, bool showActions) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${status.capitalize()} Tailors',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('tailors')
                  .where('status', isEqualTo: status)
                  .snapshots(),
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
                        Text('Error loading ${status} tailors'),
                      ],
                    ),
                  );
                }

                final tailors = snapshot.data!.docs;

                if (tailors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          _getEmptyStateIcon(status),
                          color: Colors.grey,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text('No ${status} tailors found'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tailors.length,
                  itemBuilder: (context, index) {
                    final tailorData = tailors[index].data() as Map<String, dynamic>;
                    final tailorId = tailors[index].id;
                    final name = tailorData['name'] ?? 'Unknown';
                    final email = tailorData['email'] ?? 'Unknown';
                    final phone = tailorData['phone'] ?? 'No phone provided';

                    // Check if there's a timestamp and format it
                    String dateApplied = 'Unknown date';
                    if (tailorData['createdAt'] != null) {
                      final timestamp = tailorData['createdAt'] as Timestamp;
                      final date = timestamp.toDate();
                      dateApplied = '${date.day}/${date.month}/${date.year}';
                    }

                    // Status date (when approved/rejected)
                    String statusDate = '';
                    if (status != 'pending') {
                      if (tailorData['${status}At'] != null) {
                        final timestamp = tailorData['${status}At'] as Timestamp;
                        final date = timestamp.toDate();
                        statusDate = '${date.day}/${date.month}/${date.year}';
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                                  child: FaIcon(
                                    FontAwesomeIcons.cut,
                                    color: _getStatusColor(status),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(status).withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            _buildInfoRow(FontAwesomeIcons.envelope, 'Email', email),
                            const SizedBox(height: 8),
                            _buildInfoRow(FontAwesomeIcons.phone, 'Phone', phone),
                            const SizedBox(height: 8),
                            _buildInfoRow(FontAwesomeIcons.calendar, 'Applied On', dateApplied),
                            if (status != 'pending' && statusDate.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                status == 'approved'
                                    ? FontAwesomeIcons.checkCircle
                                    : FontAwesomeIcons.timesCircle,
                                status == 'approved' ? 'Approved On' : 'Rejected On',
                                statusDate,
                              ),
                            ],

                            if (showActions) ...[
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.times,
                                      size: 14,
                                    ),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: _isLoading ? null : () => _rejectTailor(tailorId, name),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.check,
                                      size: 14,
                                    ),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _isLoading ? null : () => _approveTailor(tailorId, name),
                                  ),
                                ],
                              ),
                            ] else if (status == 'rejected') ...[
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.undoAlt,
                                      size: 14,
                                    ),
                                    label: const Text('Move to Pending'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                    ),
                                    onPressed: _isLoading ? null : () => _moveToPending(tailorId, name),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getEmptyStateIcon(String status) {
    switch (status) {
      case 'pending':
        return FontAwesomeIcons.hourglassEnd;
      case 'approved':
        return FontAwesomeIcons.clipboardCheck;
      case 'rejected':
        return FontAwesomeIcons.userTimes;
      default:
        return FontAwesomeIcons.users;
    }
  }

  Future<void> _approveTailor(String tailorId, String tailorName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a batch for atomic operations
      final batch = _db.batch();

      // Update tailor status
      final tailorRef = _db.collection('tailors').doc(tailorId);
      batch.update(tailorRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Update the user role in users collection
      batch.update(_db.collection('users').doc(tailorId), {
        'role': 'tailor',
      });

      // Commit the batch
      await batch.commit();

      // Show success message
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
              Text('$tailorName approved successfully'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error approving tailor: $e');
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectTailor(String tailorId, String tailorName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _db.collection('tailors').doc(tailorId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

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
              Text('$tailorName application rejected'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error rejecting tailor: $e');
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _moveToPending(String tailorId, String tailorName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _db.collection('tailors').doc(tailorId).update({
        'status': 'pending',
      });

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
              Text('$tailorName moved to pending'),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error moving tailor to pending: $e');
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}