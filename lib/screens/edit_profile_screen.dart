// screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final String tailorId;

  const EditProfileScreen({super.key, required this.tailorId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _locationController;
  late TextEditingController _servicesController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
    _servicesController = TextEditingController();

    // Pre-fill fields with existing data
    _fetchTailorDetails();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  Future<void> _fetchTailorDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('tailors').doc(widget.tailorId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      setState(() {
        _locationController.text = data['location'] ?? '';
        _servicesController.text = (data['services'] as List<dynamic>?)
            ?.map((service) => service.toString())
            .join(', ') ??
            '';
      });
    } catch (e) {
      print('Error fetching tailor details: $e');
    }
  }

  Future<void> _updateTailorProfile() async {
    try {
      final location = _locationController.text.trim();
      final services = _servicesController.text.split(',').map((s) => s.trim()).toList();

      await FirebaseFirestore.instance.collection('tailors').doc(widget.tailorId).update({
        'location': location,
        'services': services,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      Navigator.pop(context); // Go back to TailorDashboard
    } catch (e) {
      print('Error updating tailor profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.save),
            onPressed: _updateTailorProfile,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: FaIcon(FontAwesomeIcons.mapMarker),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _servicesController,
              decoration: const InputDecoration(
                labelText: 'Services (comma-separated)',
                prefixIcon: FaIcon(FontAwesomeIcons.scissors),
              ),
            ),
          ],
        ),
      ),
    );
  }
}