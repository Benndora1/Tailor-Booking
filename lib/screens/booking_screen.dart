// screens/booking_screen.dart
import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  final String tailorName;

  const BookingScreen({super.key, required this.tailorName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.tailorName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(selectedDate == null ? 'Select Date' : 'Date: $selectedDate'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Save booking details to Firestore
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking confirmed!')),
                );
                Navigator.pop(context);
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}