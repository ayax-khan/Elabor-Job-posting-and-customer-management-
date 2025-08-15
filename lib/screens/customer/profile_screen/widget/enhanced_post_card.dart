import 'package:elabor/models/job.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'enhanced_comment_section.dart';

class EnhancedPostCard extends StatefulWidget {
  final Job post;
  final VoidCallback? onDeleted;

  const EnhancedPostCard({
    super.key, 
    required this.post,
    this.onDeleted,
  });

  @override
  State<EnhancedPostCard> createState() => _EnhancedPostCardState();
}

class _EnhancedPostCardState extends State<EnhancedPostCard> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isDeleting = false;

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this job post? This action cannot be undone and will remove all comments.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          await _firestoreService.deleteJobPost(widget.post.id, currentUserId);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Post deleted successfully'),
                backgroundColor: Colors.green.shade600,
              ),
            );
            
            // Call the callback to refresh the parent widget
            widget.onDeleted?.call();
          }
        }
      } catch (e) {
        setState(() {
          _isDeleting = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    if (_isDeleting) {
      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.symmetric(vertical: size.height * 0.01),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade100,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting post...'),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: size.height * 0.01),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and delete button
            Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.title,
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(widget.post.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.03,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (widget.post.isHired) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              'Job Filled',
                              style: GoogleFonts.poppins(
                                fontSize: size.width * 0.03,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _deletePost,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                    tooltip: 'Delete post',
                  ),
                ],
              ),
            ),

            // Image if available
            if (widget.post.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                  right: Radius.circular(16),
                ),
                child: Image.network(
                  widget.post.imageUrl!,
                  height: size.height * 0.2,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: size.height * 0.2,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    widget.post.description,
                    style: GoogleFonts.poppins(
                      fontSize: size.width * 0.038,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.post.address}, ${widget.post.city}',
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.035,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),
                  
                  // Comments section
                  EnhancedCommentSection(post: widget.post),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

