import 'package:elabor/models/job.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'enhanced_post_card.dart';
import 'package:animate_do/animate_do.dart';

class EnhancedPostsSection extends StatefulWidget {
  final List<Job> posts;
  final VoidCallback? onPostDeleted;

  const EnhancedPostsSection({
    super.key, 
    required this.posts,
    this.onPostDeleted,
  });

  @override
  State<EnhancedPostsSection> createState() => _EnhancedPostsSectionState();
}

class _EnhancedPostsSectionState extends State<EnhancedPostsSection> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.work_outline,
              color: Colors.blue.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'My Posts',
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '${widget.posts.length} post${widget.posts.length != 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: size.height * 0.02),
        
        if (widget.posts.isEmpty)
          FadeIn(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.post_add_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: GoogleFonts.poppins(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first job post to find skilled labors',
                    style: GoogleFonts.poppins(
                      fontSize: size.width * 0.035,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              final post = widget.posts[index];
              return FadeInUp(
                delay: Duration(milliseconds: 100 * index),
                child: EnhancedPostCard(
                  post: post,
                  onDeleted: widget.onPostDeleted,
                ),
              );
            },
          ),
      ],
    );
  }
}

