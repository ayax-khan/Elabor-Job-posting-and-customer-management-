import 'package:elabor/models/job.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:elabor/widgets/animated_button.dart';
import 'package:elabor/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentDialog extends StatefulWidget {
  final Job job;
  final Function(String, String) onAddComment;

  const CommentDialog({
    super.key,
    required this.job,
    required this.onAddComment,
  });

  @override
  State<CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentLaborId;
  int _laborCommentCount = 0;
  String? _commentErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentLaborId = FirebaseAuth.instance.currentUser?.uid;
    _fetchLaborCommentCount();
  }

  Future<void> _fetchLaborCommentCount() async {
    if (_currentLaborId == null) return;
    try {
      final count = await _firestoreService.getLaborCommentCountForJob(
        widget.job.id,
        _currentLaborId!,
      );
      setState(() {
        _laborCommentCount = count;
      });
    } catch (e) {
      // Handle error, e.g., show a snackbar
      print('Error fetching comment count: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) {
      setState(() {
        _commentErrorMessage = 'Comment cannot be empty';
      });
      return;
    }

    if (_laborCommentCount >= 2) {
      setState(() {
        _commentErrorMessage = 'You\'ve already posted 2 comments.';
      });
      return;
    }

    try {
      final laborName =
          (await _firestoreService.getLaborData())?.fullName ?? 'Unknown Labor';
      await widget.onAddComment(widget.job.id, _commentController.text);
      _commentController.clear();
      await _fetchLaborCommentCount(); // Refresh count after adding comment

      if (_laborCommentCount + 1 >= 2) {
        // Check if this comment makes it 2
        if (mounted) {
          Navigator.pop(context); // Close dialog after second comment
        }
      }
    } catch (e) {
      setState(() {
        _commentErrorMessage = 'Error adding comment: $e';
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool canComment = _laborCommentCount < 2;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments',
                      style: GoogleFonts.poppins(
                        fontSize: size.width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Comments List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getCommentsStream(
                    widget.job.id,
                    widget.job.postedBy,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.04,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet',
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.04,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: size.width * 0.05,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage:
                                    comment['profilePhotoUrl'] != null
                                        ? NetworkImage(
                                          comment['profilePhotoUrl'],
                                        )
                                        : null,
                                child:
                                    comment['profilePhotoUrl'] == null
                                        ? Text(
                                          comment['laborName']?.isNotEmpty ==
                                                  true
                                              ? comment['laborName'][0]
                                                  .toUpperCase()
                                              : '?',
                                          style: GoogleFonts.poppins(
                                            fontSize: size.width * 0.04,
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : null,
                              ),
                              SizedBox(width: size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment['laborName'] ?? 'Unknown',
                                      style: GoogleFonts.poppins(
                                        fontSize: size.width * 0.04,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: size.height * 0.005),
                                    Text(
                                      comment['comment'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: size.width * 0.035,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Input Area
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _commentController,
                            label: 'Write a comment...',
                            maxLines: 2,
                            validator:
                                (value) =>
                                    null, // Validation handled by _addComment
                            enabled: canComment,
                          ),
                        ),
                        SizedBox(width: size.width * 0.02),
                        AnimatedButton(
                          text: '',
                          icon: Icons.send,
                          color: canComment ? Colors.blueAccent : Colors.grey,
                          onPressed: () => _addComment(),
                          disabled: !canComment,
                          width: size.width * 0.12,
                          height: size.height * 0.06,
                        ),
                      ],
                    ),
                    if (_commentErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _commentErrorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: size.width * 0.035,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
