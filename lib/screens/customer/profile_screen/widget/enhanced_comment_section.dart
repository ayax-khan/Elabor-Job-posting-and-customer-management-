import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elabor/models/job.dart';
import 'package:elabor/models/labor.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import '../../labor_profile_screen.dart';

class EnhancedCommentSection extends StatefulWidget {
  final Job post;

  const EnhancedCommentSection({super.key, required this.post});

  @override
  State<EnhancedCommentSection> createState() => _EnhancedCommentSectionState();
}

class _EnhancedCommentSectionState extends State<EnhancedCommentSection> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _hireLaborForJob(String laborId, String laborName) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                'Hire Labor',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Text(
                'Are you sure you want to hire $laborName for this job? This action cannot be undone and will prevent other labors from commenting.',
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
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Hire',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        await _firestoreService.hireLaborForJob(
          widget.post.id,
          laborId,
          laborName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully hired $laborName!'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error hiring labor: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _viewLaborProfile(String laborId) async {
    try {
      final laborDetails = await _firestoreService.getLaborDetailsForComment(
        laborId,
      );
      if (laborDetails != null && mounted) {
        // Create a Labor object from the details
        final labor = Labor(
          uid: laborDetails['uid'],
          fullName: laborDetails['fullName'],
          cnic: '', // Not needed for profile view
          gender: '', // Not needed for profile view
          contactNumber: laborDetails['contactNumber'],
          address: '', // Not needed for profile view
          city: '', // Not needed for profile view
          area: '', // Not needed for profile view
          email: '', // Not needed for profile view
          skills: List<String>.from(laborDetails['skills'] ?? []),
          experience: 0, // Not needed for profile view
          languages: [], // Not needed for profile view
          availability: '', // Not needed for profile view
          expectedWage: 0.0, // Not needed for profile view
          profilePhotoUrl: laborDetails['profilePhotoUrl'],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LaborProfileScreen(labor: labor),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading labor profile: $e')),
        );
      }
    }
  }

  Widget _buildCommentTile(Map<String, dynamic> comment, bool isJobHired) {
    final size = MediaQuery.of(context).size;
    final laborId = comment['laborId'] ?? '';
    final laborName = comment['laborName'] ?? 'Unknown';
    final commentText = comment['comment'] ?? '';
    final timestamp = comment['createdAt'] as Timestamp?;
    final isHiredLabor = widget.post.hiredLaborId == laborId;

    return SlideInLeft(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: size.height * 0.008),
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          color: isHiredLabor ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isHiredLabor ? Colors.green.shade300 : Colors.blue.shade200,
            width: isHiredLabor ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _viewLaborProfile(laborId),
                    child: Row(
                      children: [
                        Text(
                          laborName,
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.w600,
                            color:
                                isHiredLabor
                                    ? Colors.green.shade800
                                    : Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        if (isHiredLabor) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'HIRED',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isJobHired && !isHiredLabor)
                  ElevatedButton(
                    onPressed: () => _hireLaborForJob(laborId, laborName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Hire',
                      style: GoogleFonts.poppins(
                        fontSize: size.width * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              commentText,
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.038,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
            SizedBox(height: size.height * 0.008),
            Text(
              timestamp != null
                  ? _formatTimestamp(timestamp.toDate())
                  : 'Unknown time',
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.03,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
    final isJobHired = widget.post.isHired;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _firestoreService.getComments(
        widget.post.id,
        FirebaseAuth.instance.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading comments: ${snapshot.error}',
              style: GoogleFonts.poppins(
                color: Colors.red.shade600,
                fontSize: size.width * 0.035,
              ),
            ),
          );
        }

        final comments = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comments (${comments.length})',
                  style: GoogleFonts.poppins(
                    fontSize: size.width * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                if (isJobHired) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
            SizedBox(height: size.height * 0.015),

            if (comments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No comments yet',
                      style: GoogleFonts.poppins(
                        fontSize: size.width * 0.04,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isJobHired
                          ? 'This job has been filled'
                          : 'Be the first to comment on this job',
                      style: GoogleFonts.poppins(
                        fontSize: size.width * 0.035,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...comments.map(
                (comment) => _buildCommentTile(comment, isJobHired),
              ),
          ],
        );
      },
    );
  }
}
