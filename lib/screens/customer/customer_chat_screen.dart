import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({super.key});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  String _getOtherParticipant(List<dynamic> participants) {
    return participants.firstWhere(
      (participant) => participant != _currentUserId,
      orElse: () => '',
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final otherUserId = _getOtherParticipant(conversation['participants'] ?? []);
    final unreadCount = (conversation['unreadCounts'] as Map<String, dynamic>?)?[_currentUserId] ?? 0;
    final lastMessageTimestamp = conversation['lastMessageTimestamp'] as Timestamp?;
    final isFromMe = conversation['lastMessageSenderId'] == _currentUserId;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _firestoreService.getUserDetails(otherUserId),
      builder: (context, snapshot) {
        final userDetails = snapshot.data;
        final userName = userDetails?['name'] ?? 'Unknown User';
        final profilePictureUrl = userDetails?['profilePictureUrl'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1)),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: profilePictureUrl != null ? NetworkImage(profilePictureUrl) : null,
                  child: profilePictureUrl == null
                      ? Icon(Icons.person, size: 28, color: Colors.grey.shade600)
                      : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              userName,
              style: GoogleFonts.poppins(
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Row(
              children: [
                if (isFromMe) ...[
                  Icon(Icons.done_all, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    conversation['lastMessage'] ?? 'No messages yet',
                    style: GoogleFonts.poppins(
                      color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Text(
              _formatTimestamp(lastMessageTimestamp),
              style: GoogleFonts.poppins(
                color: unreadCount > 0 ? Colors.blue.shade600 : Colors.grey.shade500,
                fontSize: 12,
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    otherUserId: otherUserId,
                    otherUserName: userName,
                    otherUserProfilePicture: profilePictureUrl,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          'Chats',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size.width * 0.05),
        ),
        centerTitle: true,
      ),
      body: _currentUserId == null
          ? const Center(child: Text('Please log in to view chats'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getConversationsStream(_currentUserId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text('Error loading chats', style: GoogleFonts.poppins(fontSize: 18, color: Colors.red.shade600, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text('Please try again later', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }
                final conversations = snapshot.data ?? [];
                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 24),
                        Text('No conversations yet', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Text('Start chatting with labors!', style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.all(size.width * 0.04),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) => _buildConversationTile(conversations[index]),
                );
              },
            ),
    );
  }
}