// screens/admin/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      // Get total bookings
      final bookingsSnapshot = await _db.collection('bookings').get();

      setState(() {
        _totalUsers = usersSnapshot.size;
        _totalTailors = tailorsCount;
        _totalBookings = bookingsSnapshot.size;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                ),
                _buildStatCard(
                  icon: FontAwesomeIcons.userTie,
                  title: 'Total Tailors',
                  value: _totalTailors.toString(),
                  color: Colors.green,
                ),
                _buildStatCard(
                  icon: FontAwesomeIcons.calendar,
                  title: 'Total Bookings',
                  value: _totalBookings.toString(),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Add more analytics sections here
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
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
          ],
        ),
      ),
    );
  }
}