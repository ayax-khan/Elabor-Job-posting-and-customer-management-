import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/labor.dart';
import '../../service/firestore_service.dart';
import 'chat_screen.dart';

class LaborProfileScreen extends StatefulWidget {
  final Labor labor;

  const LaborProfileScreen({
    super.key,
    required this.labor,
  });

  @override
  State<LaborProfileScreen> createState() => _LaborProfileScreenState();
}

class _LaborProfileScreenState extends State<LaborProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _completedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedJobs();
  }

  Future<void> _fetchCompletedJobs() async {
    try {
      final jobs = await _firestoreService.getCompletedJobsForLabor(widget.labor.uid);
      setState(() {
        _completedJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading completed jobs: $e')),
        );
      }
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: widget.labor.uid,
          otherUserName: widget.labor.fullName,
          otherUserProfilePicture: widget.labor.profilePhotoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Labor Profile',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.all(size.width * 0.06),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: size.width * 0.3,
                    height: size.width * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: size.width * 0.15,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: widget.labor.profilePhotoUrl != null
                          ? NetworkImage(widget.labor.profilePhotoUrl!)
                          : null,
                      child: widget.labor.profilePhotoUrl == null
                          ? Icon(
                              Icons.person,
                              size: size.width * 0.12,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  
                  // Labor Name
                  Text(
                    widget.labor.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: size.width * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: size.height * 0.01),
                  
                  // Mobile Number
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone,
                          size: 18,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.labor.contactNumber,
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.04,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  
                  // Chat Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Chat',
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: size.height * 0.03),
            
            // Skills Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
              padding: EdgeInsets.all(size.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skills',
                    style: GoogleFonts.poppins(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.labor.skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          skill,
                          style: GoogleFonts.poppins(
                            fontSize: size.width * 0.035,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: size.height * 0.03),
            
            // Completed Jobs Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
              padding: EdgeInsets.all(size.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        color: Colors.green.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Completed Jobs',
                        style: GoogleFonts.poppins(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),
                  
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_completedJobs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_off_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No completed jobs yet',
                            style: GoogleFonts.poppins(
                              fontSize: size.width * 0.04,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _completedJobs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final job = _completedJobs[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['title'] ?? 'Job Title',
                                style: GoogleFonts.poppins(
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job['description'] ?? 'Job description',
                                style: GoogleFonts.poppins(
                                  fontSize: size.width * 0.035,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completed',
                                    style: GoogleFonts.poppins(
                                      fontSize: size.width * 0.03,
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            
            SizedBox(height: size.height * 0.05),
          ],
        ),
      ),
    );
  }
}

