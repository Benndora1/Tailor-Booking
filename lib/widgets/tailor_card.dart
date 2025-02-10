import 'package:flutter/material.dart';

class TailorCard extends StatelessWidget {
  final String name;
  final String location;
  final List<String> services;
  final VoidCallback? onTap; // Add this parameter

  const TailorCard({
    super.key,
    required this.name,
    required this.location,
    required this.services,
    this.onTap, // Optional onTap callback
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: $location'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: services
                  .map((service) => Chip(label: Text(service)))
                  .toList(),
            ),
          ],
        ),
        trailing: onTap != null
            ? IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: onTap, // Use the onTap callback if provided
        )
            : null,
      ),
    );
  }
}