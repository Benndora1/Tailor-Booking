// screens/bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  String _userRole = 'user';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        setState(() {
          _userRole = userDoc.data()?['role'] ?? 'user';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userRole == 'tailor' ? 'Client Bookings' : 'My Bookings'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Upcoming bookings
          _buildBookingsList('upcoming'),
          // Completed bookings
          _buildBookingsList('completed'),
          // Cancelled bookings
          _buildBookingsList('cancelled'),
        ],
      ),
      floatingActionButton: _userRole != 'tailor' ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/home');
        },
        child: const FaIcon(FontAwesomeIcons.plus),
        tooltip: 'Book New Appointment',
      ) : null,
    );
  }

  Widget _buildBookingsList(String status) {
    // Convert status to the query conditions
    List<String> statusList;
    switch (status) {
      case 'upcoming':
        statusList = ['pending', 'confirmed'];
        break;
      case 'completed':
        statusList = ['completed'];
        break;
      case 'cancelled':
        statusList = ['cancelled'];
        break;
      default:
        statusList = ['pending', 'confirmed'];
    }

    // Determine which field to query based on user role
    String queryField = _userRole == 'tailor' ? 'tailorId' : 'userId';
    String userId = _auth.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('bookings')
          .where(queryField, isEqualTo: userId)
          .where('status', whereIn: statusList)
          .orderBy('appointmentDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleExclamation,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text('Error loading bookings: ${snapshot.error}'),
              ],
            ),
          );
        }

        final bookings = snapshot.data?.docs ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  _getEmptyStateIcon(status),
                  color: Colors.grey,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyStateMessage(status),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (status == 'upcoming' && _userRole != 'tailor')
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
                      icon: const FaIcon(FontAwesomeIcons.calendarPlus),
                      label: const Text('Book a Tailor'),
                    ),
                  ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              final bookingId = bookings[index].id;

              // Format date and time
              String formattedDate = 'No date set';
              String formattedTime = '';
              if (booking['appointmentDate'] != null) {
                final timestamp = booking['appointmentDate'] as Timestamp;
                final date = timestamp.toDate();
                formattedDate = DateFormat('EEEE, MMM d, yyyy').format(date);
                formattedTime = DateFormat('h:mm a').format(date);
              }

              // Get name based on role
              final String displayName = _userRole == 'tailor'
                  ? booking['customerName'] ?? 'Customer'
                  : booking['tailorName'] ?? 'Tailor';

              // Get service type
              final serviceType = booking['serviceType'] ?? 'Appointment';

              // Get status color
              Color statusColor;
              switch (booking['status']) {
                case 'pending':
                  statusColor = Colors.orange;
                  break;
                case 'confirmed':
                  statusColor = Colors.green;
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  break;
                case 'completed':
                  statusColor = Colors.blue;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _userRole == 'tailor'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            child: FaIcon(
                              _userRole == 'tailor'
                                  ? FontAwesomeIcons.user
                                  : FontAwesomeIcons.cut,
                              color: _userRole == 'tailor' ? Colors.green : Colors.blue,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  serviceType,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              booking['status'].toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        FontAwesomeIcons.calendar,
                        'Date:',
                        formattedDate,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        FontAwesomeIcons.clock,
                        'Time:',
                        formattedTime,
                      ),
                      if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          FontAwesomeIcons.noteSticky,
                          'Notes:',
                          booking['notes'],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Action buttons
                      _buildActionButtons(context, booking['status'], bookingId,
                          _userRole == 'tailor' ? booking['userId'] : booking['tailorId']),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, String status, String bookingId, String? otherId) {
    if (_userRole == 'tailor') {
      // Tailor actions
      if (status == 'pending') {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.ban, size: 14),
              label: const Text('Decline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () => _updateBookingStatus(bookingId, 'cancelled'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.check, size: 14),
              label: const Text('Confirm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _updateBookingStatus(bookingId, 'confirmed'),
            ),
          ],
        );
      } else if (status == 'confirmed') {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.ban, size: 14),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () => _updateBookingStatus(bookingId, 'cancelled'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.check, size: 14),
              label: const Text('Complete'),
              onPressed: () => _updateBookingStatus(bookingId, 'completed'),
            ),
          ],
        );
      }
    } else {
      // User actions
      if (status == 'pending' || status == 'confirmed') {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.ban, size: 14),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () => _cancelBooking(bookingId),
            ),
            Row(
              children: [
                if (status == 'confirmed') ...[
                  OutlinedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 14),
                    label: const Text('Reschedule'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/reschedule-booking',
                        arguments: bookingId,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (otherId != null) ...[
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.solidCommentDots, size: 14),
                    label: const Text('Contact'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/contact-tailor',
                        arguments: otherId,
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        );
      } else if (status == 'completed') {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.calendarPlus, size: 14),
              label: const Text('Book Again'),
              onPressed: () {
                if (otherId != null) {
                  Navigator.pushNamed(
                    context,
                    '/book-appointment',
                    arguments: otherId,
                  );
                }
              },
            ),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.solidStar, size: 14),
              label: const Text('Review'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/review-booking',
                  arguments: bookingId,
                );
              },
            ),
          ],
        );
      }
    }

    // Default (for cancelled bookings or other states)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const FaIcon(FontAwesomeIcons.calendarPlus, size: 14),
          label: const Text('Book Again'),
          onPressed: () {
            if (otherId != null) {
              Navigator.pushNamed(
                context,
                '/book-appointment',
                arguments: otherId,
              );
            }
          },
        ),
      ],
    );
  }

  void _showCancellationDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.red),
            SizedBox(width: 12),
            Text('Cancel Booking'),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () {
              _cancelBooking(bookingId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': _userRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error cancelling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _userRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getEmptyStateIcon(String status) {
    switch (status) {
      case 'upcoming':
        return FontAwesomeIcons.calendarPlus;
      case 'completed':
        return FontAwesomeIcons.clipboardCheck;
      case 'cancelled':
        return FontAwesomeIcons.calendarXmark;
      default:
        return FontAwesomeIcons.calendar;
    }
  }

  String _getEmptyStateMessage(String status) {
    final String userType = _userRole == 'tailor' ? 'client' : 'tailor';

    switch (status) {
      case 'upcoming':
        return _userRole == 'tailor'
            ? 'You don\'t have any upcoming bookings from clients.'
            : 'You don\'t have any upcoming bookings.\nBook an appointment with a tailor to get started!';
      case 'completed':
        return 'You don\'t have any completed bookings with ${_userRole == 'tailor' ? 'clients' : 'tailors'} yet.';
      case 'cancelled':
        return 'You don\'t have any cancelled bookings.';
      default:
        return 'No bookings found.';
    }
  }
}