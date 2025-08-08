import 'package:elabor/models/job.dart';
import 'package:elabor/screens/labor/widgets/comment_dialouge.dart';
import 'package:elabor/screens/labor/widgets/jobpostcards.dart';
import 'package:elabor/screens/labor/widgets/search_filter_section.dart';
import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class LaborHomeScreen extends StatefulWidget {
  const LaborHomeScreen({super.key});

  @override
  State<LaborHomeScreen> createState() => _LaborHomeScreenState();
}

class _LaborHomeScreenState extends State<LaborHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String? _city;
  String? _area;
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterJobs);
  }

  Future<void> _fetchJobs() async {
    if (_city != null && _area != null) {
      try {
        final jobs = await _firestoreService.getJobsByArea(_city!, _area!);
        setState(() {
          _jobs = jobs;
          _filteredJobs = jobs;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching jobs: $e')));
      }
    }
  }

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredJobs =
          _jobs.where((job) {
            return job.title.toLowerCase().contains(query) ||
                job.description.toLowerCase().contains(query);
          }).toList();
    });
  }

  Future<void> _addComment(String jobId, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }
    final labor = await _firestoreService.getLaborData();
    if (labor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Labor profile not found')));
      return;
    }
    try {
      await _firestoreService.addComment(
        jobId,
        comment,
        labor.uid,
        labor.fullName,
      );
      // No need to refresh _fetchJobs since StreamBuilder updates comments
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
    }
  }

  void _showCommentDialog(Job job) {
    showDialog(
      context: context,
      builder: (context) => CommentDialog(job: job, onAddComment: _addComment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          SearchFilterSection(
            searchController: _searchController,
            onCityChanged: (city) {
              setState(() => _city = city);
              _fetchJobs();
            },
            onAreaChanged: (area) {
              setState(() => _area = area);
              _fetchJobs();
            },
            onFilterPressed: _fetchJobs,
          ),
          Expanded(
            child:
                _filteredJobs.isEmpty
                    ? Center(
                      child: Text(
                        'No jobs found',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredJobs.length,
                      itemBuilder: (context, index) {
                        final job = _filteredJobs[index];
                        return JobPostCard(
                          job: job,
                          onCommentPressed: () => _showCommentDialog(job),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
