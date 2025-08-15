import 'package:elabor/models/job.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'comment_section.dart';

class PostCard extends StatelessWidget {
  final Job post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  post.imageUrl!,
                  height: size.height * 0.2,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: GoogleFonts.poppins(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    post.address,
                    style: GoogleFonts.poppins(
                      fontSize: size.width * 0.035,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  CommentSection(post: post),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
