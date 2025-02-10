import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final String tailorName;

  const BookingScreen({super.key, required this.tailorName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      // After selecting date, prompt for time
      _selectTime(context);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  String _getFormattedDateTime() {
    if (selectedDate == null) return 'Select Date & Time';

    final date = DateFormat('EEE, MMM d, yyyy').format(selectedDate!);
    final time = selectedTime?.format(context) ?? 'Select Time';
    return '$date at $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.calendar, size: 20),
            const SizedBox(width: 8),
            Text('Book ${widget.tailorName}'),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Booking Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        FaIcon(FontAwesomeIcons.userTie,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Date & Time Selection
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.clockRotateLeft,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _getFormattedDateTime(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text('Tap to select date and time'),
                      onTap: () => _selectDate(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.circleInfo,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Important Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoItem(
                      FontAwesomeIcons.clock,
                      'Please arrive 5 minutes before your appointment',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      FontAwesomeIcons.ban,
                      'Cancellation is free up to 24 hours before the appointment',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      FontAwesomeIcons.phone,
                      'You will receive a confirmation call',
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Confirm Button
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.check),
              label: const Text('Confirm Booking'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: selectedDate != null && selectedTime != null
                  ? () {
                // Save booking details to Firestore
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.circleCheck,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text('Booking confirmed!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(
          icon,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}