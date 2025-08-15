import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/firestore_service.dart';
import '../customer/chat_screen.dart';

class LaborChatScreen extends StatefulWidget {
  const LaborChatScreen({super.key});

  @override
  State<LaborChatScreen> createState() => _LaborChatScreenState();
}

class _LaborChatScreenState extends State<LaborChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        title: Text(
          'Chats',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: size.width * 0.05,
          ),
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
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading conversations',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
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
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start chatting with customers!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(size.width * 0.04),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final participants = List<String>.from(conversation['participants'] ?? []);
                    final otherUserId = participants.firstWhere(
                      (id) => id != _currentUserId,
                      orElse: () => '',
                    );

                    if (otherUserId.isEmpty) return const SizedBox.shrink();

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _firestoreService.getUserDetails(otherUserId),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data;
                        final userName = userData?['name'] ?? 'Unknown User';
                        final userProfilePicture = userData?['profilePictureUrl'];
                        final unreadCount = (conversation['unreadCounts'] as Map<String, dynamic>?)?[_currentUserId] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(size.width * 0.04),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.blue.shade100,
                                  backgroundImage: userProfilePicture != null
                                      ? NetworkImage(userProfilePicture)
                                      : null,
                                  child: userProfilePicture == null
                                      ? Text(
                                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade600,
                                          ),
                                        )
                                      : null,
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade500,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: size.width * 0.04,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              conversation['lastMessage'] ?? 'No messages yet',
                              style: GoogleFonts.poppins(
                                fontSize: size.width * 0.035,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (conversation['lastMessageTimestamp'] != null)
                                  Text(
                                    _formatTimestamp(conversation['lastMessageTimestamp']),
                                    style: GoogleFonts.poppins(
                                      fontSize: size.width * 0.03,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    otherUserId: otherUserId,
                                    otherUserName: userName,
                                    otherUserProfilePicture: userProfilePicture,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final DateTime dateTime = timestamp.toDate();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}
