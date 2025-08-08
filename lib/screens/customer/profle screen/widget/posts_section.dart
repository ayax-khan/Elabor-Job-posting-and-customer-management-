import 'package:elabor/models/job.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'post_card.dart';
import 'package:animate_do/animate_do.dart';

class PostsSection extends StatelessWidget {
  final List<Job> posts;

  const PostsSection({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Posts',
          style: GoogleFonts.poppins(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: size.height * 0.02),
        posts.isEmpty
            ? FadeIn(
              child: Center(
                child: Text(
                  'No posts yet',
                  style: GoogleFonts.poppins(
                    fontSize: size.width * 0.04,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: PostCard(post: post),
                );
              },
            ),
      ],
    );
  }
}
