// screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft), // Add back arrow
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
      ),
      body: const Center(
        child: Text('This feature is coming soon!'), // Placeholder message
      ),
    );
  }
}