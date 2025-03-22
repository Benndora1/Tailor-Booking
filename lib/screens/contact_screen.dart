// screens/contact_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ContactScreen extends StatefulWidget {
  final String tailorId;
  final String? bookingId; // Optional - if contacting about a specific booking

  const ContactScreen({
    super.key,
    required this.tailorId,
    this.bookingId,
  });

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  String _chatId = '';
  bool _isLoading = true;
  String _tailorName = 'Tailor';
  String _userName = 'User';
  String _bookingDetails = '';

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      print('Loading chat data for tailorId: ${widget.tailorId} and userId: $userId');

      // Get tailor info
      final tailorDoc = await _db.collection('users').doc(widget.tailorId).get();
      if (tailorDoc.exists) {
        setState(() {
          _tailorName = tailorDoc.data()?['name'] ?? 'Tailor';
        });
      }

      // Get user info
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'User';
        });
      }

      // If this is about a specific booking, load booking details
      if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
        final bookingDoc = await _db.collection('bookings').doc(widget.bookingId).get();
        if (bookingDoc.exists) {
          final bookingData = bookingDoc.data()!;
          String date = 'No date';
          if (bookingData['appointmentDate'] != null) {
            final timestamp = bookingData['appointmentDate'] as Timestamp;
            final dateTime = timestamp.toDate();
            date = DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
          }
          setState(() {
            _bookingDetails = 'Booking on $date - ${bookingData['serviceType'] ?? 'Service'}';
          });
        }
      }

      // Check if chat already exists
      print('Querying for existing chat');
      final chatQuery = await _db.collection('chats')
          .where('participants', arrayContainsAny: [userId, widget.tailorId])
          .get();

      bool chatFound = false;
      for (var doc in chatQuery.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(userId) && participants.contains(widget.tailorId)) {
          setState(() {
            _chatId = doc.id;
            chatFound = true;
          });
          print('Chat found with ID: $_chatId');
          break;
        }
      }

      // If no chat exists, create one
      if (!chatFound) {
        print('Creating new chat');
        final chatRef = await _db.collection('chats').add({
          'participants': [userId, widget.tailorId],
          'participantNames': {
            userId: _userName,
            widget.tailorId: _tailorName,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _chatId = chatRef.id;
        });
        print('Created new chat with ID: $_chatId');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat data: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chat: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Check if chatId is valid
      if (_chatId.isEmpty) {
        print('Cannot send message: Chat ID is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send message: Chat not initialized')),
        );
        return;
      }

      print('Sending message to chat: $_chatId');

      // If we have a booking ID, include it in the message
      String finalMessage = message;
      if (widget.bookingId != null && widget.bookingId!.isNotEmpty && _bookingDetails.isNotEmpty) {
        finalMessage = '[$_bookingDetails]\n\n$message';
      }

      // Add message to messages subcollection
      await _db.collection('chats').doc(_chatId).collection('messages').add({
        'senderId': userId,
        'senderName': _userName,
        'message': finalMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update chat document with last message
      await _db.collection('chats').doc(_chatId).update({
        'lastMessage': finalMessage,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': userId,
      });

      // Clear message input
      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $_tailorName'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Booking info if applicable
          if (_bookingDetails.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.calendar, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bookingDetails,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: _chatId.isEmpty
                ? const Center(
              child: Text('Cannot load messages: Chat not initialized'),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: _db.collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        FaIcon(
                          FontAwesomeIcons.commentDots,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final senderId = messageData['senderId'] as String?;
                    final isMe = senderId == _auth.currentUser?.uid;
                    final message = messageData['message'] as String? ?? '';
                    final senderName = messageData['senderName'] as String? ?? 'Unknown';

                    // Format timestamp
                    String timeString = '';
                    if (messageData['timestamp'] != null) {
                      final timestamp = messageData['timestamp'] as Timestamp;
                      final dateTime = timestamp.toDate();
                      timeString = DateFormat('h:mm a').format(dateTime);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              child: const FaIcon(
                                FontAwesomeIcons.userTie,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      senderName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  Text(
                                    message,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeString,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green.withOpacity(0.2),
                              child: const FaIcon(
                                FontAwesomeIcons.user,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _chatId.isEmpty ? null : _sendMessage,
                  mini: true,
                  child: const FaIcon(FontAwesomeIcons.paperPlane),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}