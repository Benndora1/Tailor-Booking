// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/tailor_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tailors Near You')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tailors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tailors available'));
          }

          final tailors = snapshot.data!.docs;
          return ListView.builder(
            itemCount: tailors.length,
            itemBuilder: (context, index) {
              final tailorData = tailors[index].data() as Map<String, dynamic>;
              // Convert the services data to List<String>
              final servicesData = tailorData['services'];
              List<String> services = [];

              if (servicesData != null) {
                if (servicesData is List) {
                  services = servicesData.map((e) => e.toString()).toList();
                } else if (servicesData is Map) {
                  // If services is stored as a map
                  services = servicesData.values.map((e) => e.toString()).toList();
                }
              }

              return TailorCard(
                name: tailorData['name'] ?? 'Unknown',
                location: tailorData['location'] ?? 'No location',
                services: services,
              );
            },
          );
        },
      ),
    );
  }
}