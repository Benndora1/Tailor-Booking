//
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final String? tailorId; // For user making a booking
  final String? userId; // For tailor viewing bookings
  final String? bookingId; // For viewing/editing a specific booking
  final bool isRescheduling;

  const BookingScreen({
    super.key,
    this.tailorId,
    this.userId,
    this.bookingId,
    this.isRescheduling = false,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _userRole = 'user';
  String _tailorName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadExistingBooking();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        setState(() {
          _userRole = userDoc.data()?['role'] ?? 'user';
          _isLoading = false;
        });

        // If tailorId is provided, get tailor's name
        if (widget.tailorId != null) {
          await _getTailorInfo(widget.tailorId!);
        }
      }
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getTailorInfo(String tailorId) async {
    try {
      // Try to get from tailors collection first
      var tailorDoc = await _db.collection('tailors').doc(tailorId).get();

      // If not found, try users collection
      if (!tailorDoc.exists) {
        tailorDoc = await _db.collection('users').doc(tailorId).get();
      }

      if (tailorDoc.exists) {
        setState(() {
          _tailorName = tailorDoc.data()?['name'] ?? 'Tailor';
        });
      }
    } catch (e) {
      print('Error getting tailor info: $e');
    }
  }

  Future<void> _loadExistingBooking() async {
    if (widget.bookingId != null) {
      try {
        final bookingDoc = await _db.collection('bookings').doc(widget.bookingId).get();
        if (bookingDoc.exists) {
          final data = bookingDoc.data()!;

          setState(() {
            _serviceController.text = data['service'] ?? '';
            _notesController.text = data['notes'] ?? '';

            // Parse date and time
            if (data['appointmentDate'] != null) {
              final timestamp = data['appointmentDate'] as Timestamp;
              final date = timestamp.toDate();
              _selectedDate = date;
              _selectedTime = TimeOfDay(hour: date.hour, minute: date.minute);
            }

            // If we're viewing a booking and don't have tailor info yet
            if (widget.tailorId == null && data['tailorId'] != null) {
              _getTailorInfo(data['tailorId']);
            }
          });
        }
      } catch (e) {
        print('Error loading booking: $e');
      }
    }
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking(BuildContext context) async {
    try {
      if (_serviceController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please specify the service you need')),
        );
        return;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to book')),
        );
        return;
      }

      // Combine date and time
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create booking data
      final bookingData = {
        'tailorId': widget.tailorId,
        'userId': userId,
        'tailorName': _tailorName,
        'appointmentDate': Timestamp.fromDate(appointmentDateTime),
        'serviceType': _serviceController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Get user name for booking
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        bookingData['customerName'] = userDoc.data()?['name'] ?? 'Customer';
      }

      if (widget.isRescheduling && widget.bookingId != null) {
        // Update existing booking
        await _db.collection('bookings').doc(widget.bookingId).update({
          ...bookingData,
          'status': 'rescheduled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new booking
        await _db.collection('bookings').add(bookingData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context); // Go back
    } catch (e) {
      print('Error submitting booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Different UI based on role and parameters
    if (_userRole == 'tailor' && widget.userId == null) {
      // Tailor viewing their bookings
      return _buildTailorBookingsList();
    } else {
      // User making/editing a booking OR tailor viewing a specific booking
      return _buildBookingForm();
    }
  }

  // UI for a tailor to view all their bookings
  Widget _buildTailorBookingsList() {
    final tailorId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('bookings')
            .where('tailorId', isEqualTo: tailorId)
            .orderBy('appointmentDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data?.docs ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  FaIcon(
                    FontAwesomeIcons.calendar,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No bookings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your bookings will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              final bookingId = bookings[index].id;

              // Format date
              String formattedDate = 'No date';
              String formattedTime = '';
              if (booking['appointmentDate'] != null) {
                final timestamp = booking['appointmentDate'] as Timestamp;
                final date = timestamp.toDate();
                formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);
                formattedTime = DateFormat('h:mm a').format(date);
              }

              // Get status color
              Color statusColor;
              switch (booking['status']) {
                case 'pending':
                  statusColor = Colors.orange;
                  break;
                case 'confirmed':
                  statusColor = Colors.green;
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  break;
                case 'completed':
                  statusColor = Colors.blue;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking['customerName'] ?? 'Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              booking['status'].toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.calendar,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(formattedDate),
                          const SizedBox(width: 16),
                          const FaIcon(
                            FontAwesomeIcons.clock,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(formattedTime),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.tag,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(booking['serviceType'] ?? 'Service'),
                        ],
                      ),
                      if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.noteSticky,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(booking['notes']),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (booking['status'] == 'pending') ...[
                            OutlinedButton.icon(
                              icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                              label: const Text('Decline'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () => _updateBookingStatus(bookingId, 'cancelled'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                              label: const Text('Confirm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _updateBookingStatus(bookingId, 'confirmed'),
                            ),
                          ],
                          if (booking['status'] == 'confirmed') ...[
                            OutlinedButton.icon(
                              icon: const FaIcon(FontAwesomeIcons.ban, size: 14),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () => _updateBookingStatus(bookingId, 'cancelled'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                              label: const Text('Complete'),
                              onPressed: () => _updateBookingStatus(bookingId, 'completed'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // UI for user to make a booking or tailor to view a specific booking
  Widget _buildBookingForm() {
    final formTitle = widget.isRescheduling
        ? 'Reschedule Appointment'
        : 'Book Appointment with $_tailorName';

    return Scaffold(
      appBar: AppBar(
        title: Text(formTitle),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Time Selection
            const Text(
              'Appointment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.calendar, color: Colors.blue),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const FaIcon(FontAwesomeIcons.angleDown, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time Picker
            InkWell(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.clock, color: Colors.blue),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const FaIcon(FontAwesomeIcons.angleDown, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Service Type
            const Text(
              'Service Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _serviceController,
              decoration: const InputDecoration(
                labelText: 'Service Type',
                hintText: 'E.g., Tailoring, Alterations, Custom Design',
                prefixIcon: Icon(Icons.design_services),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any specific requirements or details',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitBooking(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.isRescheduling ? 'Reschedule Appointment' : 'Request Booking',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update booking status for tailor actions
  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}