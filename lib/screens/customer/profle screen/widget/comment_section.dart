import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elabor/models/job.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';

class CommentSection extends StatelessWidget {
  final Job post;

  const CommentSection({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final firestoreService = FirestoreService();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: firestoreService.getComments(
        post.id,
        FirebaseAuth.instance.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text(
            'No comments yet',
            style: GoogleFonts.poppins(
              fontSize: size.width * 0.035,
              color: Colors.grey[600],
            ),
          );
        }
        final comments = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments',
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            ...comments.map(
              (comment) => SlideInLeft(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: size.height * 0.005),
                  padding: EdgeInsets.all(size.width * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['laborName'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        comment['comment'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: size.width * 0.035,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        (comment['createdAt'] as Timestamp?)
                                ?.toDate()
                                .toString() ??
                            '',
                        style: GoogleFonts.poppins(
                          fontSize: size.width * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
