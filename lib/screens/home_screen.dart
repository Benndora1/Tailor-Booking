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
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _db.collection('users').doc(user.uid).get();
        setState(() {
          _userName = userData.data()?['name'] ?? 'User';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Stream<QuerySnapshot> _getTailors() {
    return _db
        .collection('tailors')         // Fetch from tailors collection for more details
        .where('status', isEqualTo: 'approved')  // Only show approved tailors
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
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.magnifyingGlass),
            onPressed: () {
              // Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon')),
              );
            },
            tooltip: 'Search Tailors',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                    final tailorId = tailors[index].id;
                    final name = tailor['name'] ?? 'Unknown';
                    final bio = tailor['bio'] ?? 'No bio available';

                    // Calculate rating
                    final rating = tailor['rating'] ?? 0.0;
                    final reviewCount = tailor['reviewCount'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/tailor-details',
                            arguments: tailorId,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    child: const FaIcon(
                                      FontAwesomeIcons.userTie,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            FaIcon(
                                              FontAwesomeIcons.star,
                                              size: 14,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$rating',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '($reviewCount reviews)',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/book-appointment',
                                        arguments: tailorId,
                                      );
                                    },
                                    icon: const FaIcon(
                                      FontAwesomeIcons.calendarPlus,
                                      size: 14,
                                    ),
                                    label: const Text('Book'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                bio,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (tailor['specialties'] != null &&
                                  (tailor['specialties'] as List).isNotEmpty) ...[
                                const Text(
                                  'Specialties:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (tailor['specialties'] as List)
                                      .map((specialty) => Chip(
                                    label: Text(
                                      specialty.toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                  ))
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/tailor-details',
                                      arguments: tailorId,
                                    );
                                  },
                                  icon: const Text('View Details'),
                                  label: const FaIcon(
                                    FontAwesomeIcons.angleRight,
                                    size: 14,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to filter/search page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Advanced search coming soon')),
          );
        },
        child: const FaIcon(FontAwesomeIcons.filter),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', true),
            _buildFilterChip('Clothing', false),
            _buildFilterChip('Wedding', false),
            _buildFilterChip('Alterations', false),
            _buildFilterChip('Custom Design', false),
            _buildFilterChip('Nearest', false),
            _buildFilterChip('Top Rated', false),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // Handle filter selection
        },
        selectedColor: Colors.blue.withOpacity(0.2),
        checkmarkColor: Colors.blue,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.shirt,
                      size: 40,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: FaIcon(
                        FontAwesomeIcons.user,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Welcome, $_userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Home Section - Find Tailors
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'MAIN MENU',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.shirt),
            title: const Text('Find Tailors'),
            selected: true,
            selectedTileColor: Colors.blue.withOpacity(0.1),
            selectedColor: Colors.blue,
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.calendar),
            title: const Text('My Bookings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/bookings');
            },
          ),

          const Divider(),

          // Profile & Settings
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'PROFILE & SETTINGS',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.userPen),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.gear),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),

          const Divider(),

          ListTile(
            leading: const FaIcon(FontAwesomeIcons.rightFromBracket),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}