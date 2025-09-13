import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfilePicture;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfilePicture,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversationId;
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_currentUserId == null) return;

      _conversationId = await _firestoreService.getOrCreateConversation(
        _currentUserId!,
        widget.otherUserId,
      );

      // Mark messages as read when opening chat
      await _firestoreService.markMessagesAsRead(
        _conversationId!,
        _currentUserId!,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error initializing chat: $e')));
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _conversationId == null ||
        _currentUserId == null) {
      return;
    }

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    try {
      await _firestoreService.sendMessage(
        _conversationId!,
        _currentUserId!,
        widget.otherUserId,
        messageContent,
      );

      // Scroll to bottom after sending message
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error making phone call: $e')));
      }
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final timestamp = message['timestamp'] as Timestamp?;
    final timeString =
        timestamp != null
            ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
            : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['content'] ?? '',
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeString,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white70 : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.otherUserName,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  widget.otherUserProfilePicture != null
                      ? NetworkImage(widget.otherUserProfilePicture!)
                      : null,
              child:
                  widget.otherUserProfilePicture == null
                      ? Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.grey.shade600,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _firestoreService.getUserDetails(widget.otherUserId),
            builder: (context, snapshot) {
              final userDetails = snapshot.data;
              final phoneNumber =
                  userDetails?['contactNumber'] ?? userDetails?['phoneNumber'];

              return IconButton(
                icon: const Icon(Icons.phone, color: Colors.blue),
                onPressed:
                    phoneNumber != null
                        ? () {
                          _makePhoneCall(phoneNumber);
                        }
                        : null,
                tooltip: 'Call ${widget.otherUserName}',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child:
                _conversationId == null
                    ? const Center(child: Text('Unable to load conversation'))
                    : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firestoreService.getMessagesStream(
                        _conversationId!,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final messages = snapshot.data ?? [];

                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start a conversation with ${widget.otherUserName}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message['senderId'] == _currentUserId;
                            return _buildMessageBubble(message, isMe);
                          },
                        );
                      },
                    ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
