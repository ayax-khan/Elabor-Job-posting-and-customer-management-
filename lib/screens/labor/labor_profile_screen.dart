import 'package:elabor/models/labor.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class LaborProfileScreen extends StatelessWidget {
  const LaborProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final String? laborId = FirebaseAuth.instance.currentUser?.uid;

    print('LaborProfileScreen: laborId = $laborId'); // Debug: Check auth

    if (laborId == null) {
      return Center(
        child: Text(
          'Please sign in',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: FutureBuilder<Labor?>(
          future: firestoreService.getLaborData(),
          builder: (context, snapshot) {
            print(
              'FutureBuilder: connectionState = ${snapshot.connectionState}',
            ); // Debug: Check state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print(
                'FutureBuilder: error = ${snapshot.error}',
              ); // Debug: Log error
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData) {
              print('FutureBuilder: no data'); // Debug: No labor data
              return Center(
                child: Text(
                  'No profile data found',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              );
            }
            final labor = snapshot.data!;
            print(
              'FutureBuilder: labor = ${labor.fullName}, ${labor.address}',
            ); // Debug: Check labor
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundImage:
                            labor.profilePhotoUrl != null
                                ? NetworkImage(labor.profilePhotoUrl!)
                                : null,
                        child:
                            labor.profilePhotoUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white,
                                )
                                : null,
                        backgroundColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        labor.fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Profile Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Details',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.location_on,
                            'Address',
                            labor.address,
                          ),
                          _buildInfoRow(
                            Icons.phone,
                            'Phone',
                            labor.contactNumber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Completed Jobs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Completed Jobs',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                // FutureBuilder<List<Job>>(
                //   future: firestoreService.getLaborCompletedJobs(laborId),
                //   builder: (context, jobSnapshot) {
                //     print('Jobs FutureBuilder: state = ${jobSnapshot.connectionState}'); // Debug
                //     if (jobSnapshot.connectionState == ConnectionState.waiting) {
                //       return const Center(child: CircularProgressIndicator());
                //     }
                //     if (jobSnapshot.hasError) {
                //       print('Jobs FutureBuilder: error = ${jobSnapshot.error}'); // Debug
                //       return Center(
                //         child: Text(
                //           'Error: ${jobSnapshot.error}',
                //           style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                //         ),
                //       );
                //     }
                //     if (!jobSnapshot.hasData || jobSnapshot.data!.isEmpty) {
                //       print('Jobs FutureBuilder: no jobs'); // Debug
                //       return Padding(
                //         padding: const EdgeInsets.all(16.0),
                //         child: Text(
                //           'No completed jobs yet',
                //           style: GoogleFonts.poppins(
                //             fontSize: 14,
                //             color: Colors.grey.shade600,
                //           ),
                //         ),
                //       );
                //     }
                //     final jobs = jobSnapshot.data!;
                //     return ListView.builder(
                //       shrinkWrap: true,
                //       physics: const NeverScrollableScrollPhysics(),
                //       itemCount: jobs.length,
                //       itemBuilder: (context, index) {
                //         final job = jobs[index];
                //         return Card(
                //           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                //           elevation: 2,
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //           child: Padding(
                //             padding: const EdgeInsets.all(12.0),
                //             child: Row(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 job.imageUrl != null
                //                     ? ClipRRect(
                //                         borderRadius: BorderRadius.circular(8),
                //                         child: Image.network(
                //                           job.imageUrl!,
                //                           width: 80,
                //                           height: 80,
                //                           fit: BoxFit.cover,
                //                           errorBuilder: (context, error, stackTrace) =>
                //                               const Icon(Icons.work, size: 80),
                //                         ),
                //                       )
                //                     : const Icon(Icons.work, size: 80),
                //                 const SizedBox(width: 12),
                //                 Expanded(
                //                   child: Column(
                //                     crossAxisAlignment: CrossAxisAlignment.start,
                //                     children: [
                //                       Text(
                //                         job.title,
                //                         style: GoogleFonts.poppins(
                //                           fontSize: 16,
                //                           fontWeight: FontWeight.bold,
                //                         ),
                //                       ),
                //                       const SizedBox(height: 4),
                //                       Text(
                //                         job.description,
                //                         style: GoogleFonts.poppins(
                //                           fontSize: 14,
                //                           color: Colors.grey.shade600,
                //                         ),
                //                         maxLines: 3,
                //                         overflow: TextOverflow.ellipsis,
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ),
                //         );
                //       },
                //     );
                //   },
                // ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade800, size: 24),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
