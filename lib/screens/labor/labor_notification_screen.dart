import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/firestore_service.dart';
import '../customer/chat_screen.dart';
import 'job_management_screen.dart';

class LaborNotificationScreen extends StatefulWidget {
  const LaborNotificationScreen({super.key});

  @override
  State<LaborNotificationScreen> createState() =>
      _LaborNotificationScreenState();
}

class _LaborNotificationScreenState extends State<LaborNotificationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
          'Notifications',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: size.width * 0.05,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: Colors.white),
            onPressed: () async {
              // Mark all notifications as read
              try {
                await _firestoreService.markAllNotificationsAsRead(
                  _currentUserId!,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          ),
        ],
      ),
      body:
          _currentUserId == null
              ? const Center(child: Text('Please log in to view notifications'))
              : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.getNotificationsStream(
                  _currentUserId!,
                ),
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
                            'Error loading notifications',
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

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll see notifications here when you get hired or complete jobs',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(size.width * 0.04),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isRead = notification['isRead'] ?? false;
                      final type = notification['type'] ?? '';
                      final title = notification['title'] ?? '';
                      final message = notification['message'] ?? '';
                      final timestamp = notification['timestamp'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isRead
                                    ? Colors.grey.shade200
                                    : Colors.blue.shade200,
                            width: 1,
                          ),
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
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(
                                type,
                              ).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getNotificationIcon(type),
                              color: _getNotificationColor(type),
                              size: 24,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontWeight:
                                        isRead
                                            ? FontWeight.w500
                                            : FontWeight.w600,
                                    fontSize: size.width * 0.04,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: GoogleFonts.poppins(
                                  fontSize: size.width * 0.035,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTimestamp(timestamp),
                                style: GoogleFonts.poppins(
                                  fontSize: size.width * 0.03,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            // Mark notification as read
                            if (!isRead) {
                              await _firestoreService.markNotificationAsRead(
                                notification['id'],
                              );
                            }

                            // Handle notification tap based on type
                            if (type == 'laborHired' &&
                                notification['additionalData']?['jobId'] !=
                                    null) {
                              // Navigate to job management screen
                              final jobId =
                                  notification['additionalData']['jobId'];
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            JobManagementScreen(jobId: jobId),
                                  ),
                                );
                              }
                            }
                            // For other job-related notifications, also navigate to job management
                            else if ((type == 'jobConfirmed' ||
                                    type == 'jobNotConfirmed') &&
                                notification['additionalData']?['jobId'] !=
                                    null) {
                              final jobId =
                                  notification['additionalData']['jobId'];
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            JobManagementScreen(jobId: jobId),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'laborHired':
        return Icons.work;
      case 'jobCompleted':
        return Icons.check_circle;
      case 'jobCancelled':
        return Icons.cancel;
      case 'jobConfirmed':
        return Icons.verified;
      case 'jobNotConfirmed':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'laborHired':
        return Colors.green;
      case 'jobCompleted':
        return Colors.blue;
      case 'jobCancelled':
        return Colors.red;
      case 'jobConfirmed':
        return Colors.green;
      case 'jobNotConfirmed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      final DateTime dateTime = timestamp.toDate();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}
