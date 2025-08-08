import 'package:elabor/models/job.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:elabor/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentsSection extends StatefulWidget {
  final Job job;
  final Function(String, String) onAddComment;

  const CommentsSection({
    super.key,
    required this.job,
    required this.onAddComment,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Comments',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _firestoreService.getComments(
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
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
                ),
              );
            }
            final comments = snapshot.data ?? [];
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No comments yet',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
              );
            }
            return Column(
              children:
                  comments.map((comment) {
                    return ListTile(
                      title: Text(
                        comment['laborName'],
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        comment['comment'],
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _commentController,
                  label: 'Add Comment',
                  maxLines: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: () {
                  if (_commentController.text.isNotEmpty) {
                    widget.onAddComment(widget.job.id, _commentController.text);
                    _commentController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
