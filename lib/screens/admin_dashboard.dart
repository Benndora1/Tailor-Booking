// screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'user_management.dart';
import 'tailor_approval.dart';
import 'analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              context,
              title: 'User Management',
              icon: FontAwesomeIcons.users,
              color: Colors.blue,
              route: '/admin/users',
            ),
            _buildDashboardCard(
              context,
              title: 'Tailor Approval',
              icon: FontAwesomeIcons.userCheck,
              color: Colors.green,
              route: '/admin/tailor-approval',
            ),
            _buildDashboardCard(
              context,
              title: 'Analytics',
              icon: FontAwesomeIcons.chartBar,
              color: Colors.orange,
              route: '/admin/analytics',
            ),
            _buildDashboardCard(
              context,
              title: 'Settings',
              icon: FontAwesomeIcons.cog,
              color: Colors.purple,
              route: '/admin/settings',
            ),
          ],
        ),
      ),
    );
  }

  /// Build the drawer for navigation
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.userGear,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage your application',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.home),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.users),
            title: const Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/users');
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.userCheck),
            title: const Text('Tailor Approval'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/tailor-approval');
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.chartBar),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/analytics');
            },
          ),
          const Divider(),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.signOutAlt),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await _authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required String route,
      }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}