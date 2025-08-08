import 'package:elabor/models/customer.dart';
import 'package:elabor/models/job.dart';
import 'package:elabor/screens/labor/widgets/image_viewer_screen.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JobPostCard extends StatelessWidget {
  final Job job;
  final VoidCallback onCommentPressed;

  const JobPostCard({
    super.key,
    required this.job,
    required this.onCommentPressed,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Info
          FutureBuilder<Customer?>(
            future: firestoreService.getCustomerData(),
            builder: (context, snapshot) {
              String posterName = 'Unknown';
              String? posterPhotoUrl;
              if (snapshot.hasData && snapshot.data != null) {
                posterName = snapshot.data!.name;
                posterPhotoUrl = snapshot.data!.profilePhotoUrl;
              }
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      posterPhotoUrl != null
                          ? NetworkImage(posterPhotoUrl)
                          : null,
                  child:
                      posterPhotoUrl == null ? const Icon(Icons.person) : null,
                  backgroundColor: Colors.grey.shade300,
                ),
                title: Text(
                  posterName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // subtitle: Text(
                //   DateFormat('MMM d, yyyy • h:mm a').format(job.createdAt),
                //   style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                // ),
              );
            },
          ),
          // Job Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              job.title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              job.description,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          if (job.imageUrl != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ImageViewerScreen(imageUrl: job.imageUrl!),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  job.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Location: ${job.address}, ${job.area}, ${job.city}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Divider(),
          // Actions
          FutureBuilder<List<Map<String, dynamic>>>(
            future: firestoreService.getComments(job.id, job.postedBy),
            builder: (context, snapshot) {
              int commentCount = snapshot.data?.length ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.blueAccent),
                      onPressed: onCommentPressed,
                    ),
                    Text(
                      commentCount == 0
                          ? 'Comment'
                          : '$commentCount Comment${commentCount > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
