// screens/admin/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _totalUsers = 0;
  int _totalTailors = 0;
  int _totalBookings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get total users
      final usersSnapshot = await _db.collection('users').get();
      // Get total tailors
      final tailorsCount = usersSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'tailor')
          .length;

      // Try to get bookings with error handling
      int bookingsCount = 0;
      try {
        final bookingsSnapshot = await _db.collection('bookings').get();
        bookingsCount = bookingsSnapshot.size;
      } catch (bookingError) {
        print('Error getting bookings: $bookingError');
        // Continue with zero bookings
      }

      setState(() {
        _totalUsers = usersSnapshot.size;
        _totalTailors = tailorsCount;
        _totalBookings = bookingsCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading analytics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.sync),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  FaIcon(
                    FontAwesomeIcons.chartPie,
                    color: Colors.blue,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Dashboard Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    icon: FontAwesomeIcons.users,
                    title: 'Total Users',
                    value: _totalUsers.toString(),
                    color: Colors.blue,
                    onTap: () => _showDetailScreen('users'),
                  ),
                  _buildStatCard(
                    icon: FontAwesomeIcons.cut,
                    title: 'Total Tailors',
                    value: _totalTailors.toString(),
                    color: Colors.green,
                    onTap: () => _showDetailScreen('tailors'),
                  ),
                  _buildStatCard(
                    icon: FontAwesomeIcons.calendarCheck,
                    title: 'Total Bookings',
                    value: _totalBookings.toString(),
                    color: Colors.orange,
                    onTap: () => _showDetailScreen('bookings'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: const [
                  FaIcon(
                    FontAwesomeIcons.calendarAlt,
                    color: Colors.blue,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Add a recent activity section
              _buildRecentActivityList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.27,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              FaIcon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 4),
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 10,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return FutureBuilder<QuerySnapshot>(
      future: _db.collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get()
          .catchError((error) {
        print('Error fetching recent bookings: $error');
        return null;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: const [
                  FaIcon(
                    FontAwesomeIcons.exclamationCircle,
                    color: Colors.amber,
                    size: 24,
                  ),
                  SizedBox(height: 8),
                  Text('Unable to load recent activity'),
                ],
              ),
            ),
          );
        }

        final bookings = snapshot.data!.docs;

        if (bookings.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: const [
                  FaIcon(
                    FontAwesomeIcons.calendarTimes,
                    color: Colors.grey,
                    size: 24,
                  ),
                  SizedBox(height: 8),
                  Text('No recent bookings'),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final bookingData = bookings[index].data() as Map<String, dynamic>;
            final bookingId = bookings[index].id;

            // Default values in case data is missing
            final customerName = bookingData['customerName'] ?? 'Unknown Customer';
            final tailorName = bookingData['tailorName'] ?? 'Unknown Tailor';
            final status = bookingData['status'] ?? 'pending';

            // Format timestamp if available
            String dateStr = 'Unknown Date';
            if (bookingData['createdAt'] != null) {
              final timestamp = bookingData['createdAt'] as Timestamp;
              final date = timestamp.toDate();
              dateStr = '${date.day}/${date.month}/${date.year}';
            }

            // Choose icon and color based on status
            IconData statusIcon;
            Color statusColor;

            switch (status) {
              case 'completed':
                statusIcon = FontAwesomeIcons.checkCircle;
                statusColor = Colors.green;
                break;
              case 'cancelled':
                statusIcon = FontAwesomeIcons.timesCircle;
                statusColor = Colors.red;
                break;
              case 'in_progress':
                statusIcon = FontAwesomeIcons.hourglass;
                statusColor = Colors.orange;
                break;
              default:
                statusIcon = FontAwesomeIcons.clock;
                statusColor = Colors.blue;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: FaIcon(
                    statusIcon,
                    color: statusColor,
                    size: 16,
                  ),
                ),
                title: Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Tailor: $tailorName • $dateStr'),
                trailing: Container(
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
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                onTap: () => _showBookingDetails(bookingId),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetailScreen(String type) {
    switch (type) {
      case 'users':
        _showUsersDetailScreen();
        break;
      case 'tailors':
        _showTailorsDetailScreen();
        break;
      case 'bookings':
        _showBookingsDetailScreen();
        break;
    }
  }

  void _showUsersDetailScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          FaIcon(FontAwesomeIcons.users, color: Colors.blue),
                          SizedBox(width: 12),
                          Text(
                            'User Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.times),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(
                            child: Text('Error loading users'),
                          );
                        }

                        final users = snapshot.data!.docs;

                        if (users.isEmpty) {
                          return const Center(
                            child: Text('No users found'),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userData = users[index].data() as Map<String, dynamic>;
                            final email = userData['email'] ?? 'Unknown';
                            final name = userData['name'] ?? userData['displayName'] ?? email;
                            final role = userData['role'] ?? 'user';

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
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: roleColor.withOpacity(0.2),
                                  child: FaIcon(
                                    roleIcon,
                                    color: roleColor,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(email),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          },
        );
      },
    );
  }

  void _showTailorsDetailScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          FaIcon(FontAwesomeIcons.cut, color: Colors.green),
                          SizedBox(width: 12),
                          Text(
                            'Tailor Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.times),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('users')
                          .where('role', isEqualTo: 'tailor')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(
                            child: Text('Error loading tailors'),
                          );
                        }

                        final tailors = snapshot.data!.docs;

                        if (tailors.isEmpty) {
                          return const Center(
                            child: Text('No tailors found'),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: tailors.length,
                          itemBuilder: (context, index) {
                            final userData = tailors[index].data() as Map<String, dynamic>;
                            final email = userData['email'] ?? 'Unknown';
                            final name = userData['name'] ?? userData['displayName'] ?? email;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: FaIcon(
                                    FontAwesomeIcons.cut,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(email),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.info,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        // Show tailor profile detail
                                      },
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
            );
          },
        );
      },
    );
  }

  void _showBookingsDetailScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          FaIcon(FontAwesomeIcons.calendarCheck, color: Colors.orange),
                          SizedBox(width: 12),
                          Text(
                            'Booking Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.times),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Add filter options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFilterChip('All', true),
                      _buildFilterChip('Pending', false),
                      _buildFilterChip('In Progress', false),
                      _buildFilterChip('Completed', false),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future: _db.collection('bookings')
                          .orderBy('createdAt', descending: true)
                          .get()
                          .catchError((error) {
                        print('Error fetching bookings: $error');
                        return null;
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                          return const Center(
                            child: Text('Error loading bookings'),
                          );
                        }

                        final bookings = snapshot.data!.docs;

                        if (bookings.isEmpty) {
                          return const Center(
                            child: Text('No bookings found'),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final bookingData = bookings[index].data() as Map<String, dynamic>;
                            final bookingId = bookings[index].id;

                            final customerName = bookingData['customerName'] ?? 'Unknown Customer';
                            final tailorName = bookingData['tailorName'] ?? 'Unknown Tailor';
                            final status = bookingData['status'] ?? 'pending';

                            String dateStr = 'Unknown Date';
                            if (bookingData['createdAt'] != null) {
                              final timestamp = bookingData['createdAt'] as Timestamp;
                              final date = timestamp.toDate();
                              dateStr = '${date.day}/${date.month}/${date.year}';
                            }

                            IconData statusIcon;
                            Color statusColor;

                            switch (status) {
                              case 'completed':
                                statusIcon = FontAwesomeIcons.checkCircle;
                                statusColor = Colors.green;
                                break;
                              case 'cancelled':
                                statusIcon = FontAwesomeIcons.timesCircle;
                                statusColor = Colors.red;
                                break;
                              case 'in_progress':
                                statusIcon = FontAwesomeIcons.hourglass;
                                statusColor = Colors.orange;
                                break;
                              default:
                                statusIcon = FontAwesomeIcons.clock;
                                statusColor = Colors.blue;
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withOpacity(0.2),
                                  child: FaIcon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  customerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tailor: $tailorName'),
                                    Text('Date: $dateStr'),
                                  ],
                                ),
                                trailing: Container(
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
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                isThreeLine: true,
                                onTap: () => _showBookingDetails(bookingId),
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
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // Implement filtering logic
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }

  void _showBookingDetails(String bookingId) {
    // Navigate to a detailed view of a specific booking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing booking $bookingId')),
    );
  }
}