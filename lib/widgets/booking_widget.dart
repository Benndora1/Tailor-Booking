// widgets/booking_widget.dart
import 'package:flutter/material.dart';
import '../models/booking.dart';

class BookingWidget extends StatelessWidget {
  final Booking booking;

  const BookingWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('Booking ID: ${booking.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${booking.date}'),
            Text('Status: ${booking.status}'),
          ],
        ),
      ),
    );
  }
}