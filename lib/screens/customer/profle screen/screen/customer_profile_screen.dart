import 'package:elabor/screens/customer/profle%20screen/widget/posts_section.dart';
import 'package:elabor/screens/customer/profle%20screen/widget/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../service/firestore_service.dart';
import '../../../../models/customer.dart';
import '../../../../models/job.dart';
import '../../job_post_dialog.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Customer? _customer;
  List<Job> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final customer = await _firestoreService.getCustomerData();
    final posts = await _firestoreService.getCustomerPosts(
      FirebaseAuth.instance.currentUser!.uid,
    );
    setState(() {
      _customer = customer;
      _posts = posts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05,
                    vertical: size.height * 0.03,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileHeader(customer: _customer),
                      SizedBox(height: size.height * 0.04),
                      PostsSection(posts: _posts),
                    ],
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (context) => JobPostDialog(
                  onJobPosted: _fetchData, // Refresh posts after posting
                ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
