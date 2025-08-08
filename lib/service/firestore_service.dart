import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/labor.dart';
import '../models/customer.dart';
import '../models/job.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save user roles
  Future<void> _addUserRole(String uid, String role) async {
    try {
      final roleDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('roles')
          .doc('data');
      final doc = await roleDoc.get();
      List<String> roles =
          doc.exists && doc.data() != null && doc.data()!['roles'] != null
              ? List<String>.from(doc.data()!['roles'])
              : [];
      if (!roles.contains(role)) {
        roles.add(role);
        await roleDoc.set({'roles': roles});
      }
    } catch (e) {
      throw Exception('Failed to add user role: $e');
    }
  }

  // Get user roles
  Future<List<String>> getUserRoles(String uid) async {
    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('roles')
              .doc('data')
              .get();
      if (doc.exists && doc.data() != null && doc.data()!['roles'] != null) {
        return List<String>.from(doc.data()!['roles']);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch user roles: $e');
    }
  }

  // Save labor data
  Future<void> saveLaborData(
    String uid,
    String fullName,
    String cnic,
    String gender,
    String contactNumber,
    String address,
    String city,
    String area,
    List<String> skills,
    int experience,
    List<String> languages,
    String availability,
    double expectedWage,
    String? profilePhotoUrl,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? skillProofUrl,
  ) async {
    try {
      // Input validation
      if (fullName.isEmpty) throw Exception('Full name cannot be empty');
      if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(cnic))
        throw Exception('Invalid CNIC format');
      if (contactNumber.isEmpty)
        throw Exception('Contact number cannot be empty');
      if (address.isEmpty) throw Exception('Address cannot be empty');
      if (city.isEmpty) throw Exception('City cannot be empty');
      if (area.isEmpty) throw Exception('Area cannot be empty');
      if (skills.isEmpty) throw Exception('Skills cannot be empty');
      if (languages.isEmpty) throw Exception('Languages cannot be empty');
      if (expectedWage <= 0) throw Exception('Expected wage must be positive');

      final laborData = {
        'fullName': fullName,
        'cnic': cnic,
        'gender': gender,
        'contactNumber': contactNumber,
        'address': address,
        'city': city,
        'area': area,
        'email': _auth.currentUser?.email ?? '',
        'skills': skills,
        'experience': experience,
        'languages': languages,
        'availability': availability,
        'expectedWage': expectedWage,
        'profilePhotoUrl': profilePhotoUrl,
        'cnicFrontUrl': cnicFrontUrl,
        'cnicBackUrl': cnicBackUrl,
        'skillProofUrl': skillProofUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('labors').doc(uid).set(laborData);
      await _addUserRole(uid, 'labor');
    } catch (e) {
      throw Exception('Failed to save labor data: $e');
    }
  }

  // Save customer data
  Future<void> saveCustomerData(
    String uid,
    String name,
    String phoneNumber,
    String? profilePhotoUrl,
  ) async {
    try {
      if (name.isEmpty) throw Exception('Name cannot be empty');
      if (phoneNumber.isEmpty) throw Exception('Phone number cannot be empty');

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('customerProfile')
          .doc('data')
          .set({
            'name': name,
            'phoneNumber': phoneNumber,
            'email': _auth.currentUser?.email ?? '',
            'profilePhotoUrl': profilePhotoUrl,
          });
      await _addUserRole(uid, 'customer');
    } catch (e) {
      throw Exception('Failed to save customer data: $e');
    }
  }

  // Get labor data
  Future<Labor?> getLaborData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final roles = await getUserRoles(uid);
      if (!roles.contains('labor')) return null;
      final doc = await _firestore.collection('labors').doc(uid).get();
      if (!doc.exists) return null;
      return Labor.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch labor data: $e');
    }
  }

  // Get customer data
  Future<Customer?> getCustomerData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final roles = await getUserRoles(uid);
      if (!roles.contains('customer')) return null;
      final doc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('customerProfile')
              .doc('data')
              .get();
      if (!doc.exists) return null;
      return Customer.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch customer data: $e');
    }
  }

  // Post a job
  Future<void> postJob(
    String title,
    String description,
    String address,
    String city,
    String area,
    String? imageUrl,
  ) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');
      if (title.isEmpty) throw Exception('Job title cannot be empty');
      if (description.isEmpty)
        throw Exception('Job description cannot be empty');
      if (address.isEmpty) throw Exception('Address cannot be empty');
      if (city.isEmpty) throw Exception('City cannot be empty');
      if (area.isEmpty) throw Exception('Area cannot be empty');

      final jobData = {
        'title': title,
        'description': description,
        'address': address,
        'city': city,
        'area': area,
        'imageUrl': imageUrl,
        'postedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to jobs collection
      final jobRef = await _firestore.collection('jobs').add(jobData);

      // Save to user's customerProfile posts subcollection
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('customerProfile')
          .doc('data')
          .collection('posts')
          .doc(jobRef.id)
          .set(jobData);
    } catch (e) {
      throw Exception('Failed to post job: $e');
    }
  }

  // Get customer's posted jobs
  Future<List<Job>> getCustomerPosts(String uid) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('customerProfile')
              .doc('data')
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .get();
      return snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer posts: $e');
    }
  }

  // Add a comment to a job post
  Future<void> addComment(
    String jobId,
    String comment,
    String laborId,
    String laborName,
  ) async {
    try {
      final commentData = {
        'laborId': laborId,
        'laborName': laborName,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store in jobs collection
      await _firestore
          .collection('jobs')
          .doc(jobId)
          .collection('comments')
          .add(commentData);

      // Store in customer's postedJobs collection (if exists)
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final customerUid = jobDoc.data()?['postedBy'] as String?;
      if (customerUid != null) {
        await _firestore
            .collection('users')
            .doc(customerUid)
            .collection('postedJobs')
            .doc(jobId)
            .collection('comments')
            .add(commentData);
      }
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(
    String jobId,
    String postedBy,
  ) {
    return _firestore
        .collection('jobs')
        .doc(jobId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get comments for a job post
  Future<List<Map<String, dynamic>>> getComments(
    String postId,
    String customerUid,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(customerUid)
              .collection('postedJobs')
              .doc(postId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  // Get jobs by city and area
  Future<List<Job>> getJobsByArea(String city, String area) async {
    try {
      if (city.isEmpty) throw Exception('City cannot be empty');
      if (area.isEmpty) throw Exception('Area cannot be empty');

      final query =
          await _firestore
              .collection('jobs')
              .where('city', isEqualTo: city)
              .where('area', isEqualTo: area)
              .get();
      return query.docs.map((doc) => Job.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  // Get labors by city, area, and optional search
  Future<List<Labor>> getLaborsByArea(
    String? city,
    String? area,
    String? search,
  ) async {
    try {
      Query query = _firestore.collection('labors');
      if (city != null && city.isNotEmpty)
        query = query.where('city', isEqualTo: city);
      if (area != null && area.isNotEmpty)
        query = query.where('area', isEqualTo: area);
      final snapshot = await query.get();
      List<Labor> labors =
          snapshot.docs.map((doc) => Labor.fromFirestore(doc)).toList();
      if (search != null && search.isNotEmpty) {
        labors =
            labors
                .where(
                  (labor) => labor.fullName.toLowerCase().contains(
                    search.toLowerCase(),
                  ),
                )
                .toList();
      }
      return labors;
    } catch (e) {
      throw Exception('Failed to fetch labors: $e');
    }
  }

  // Get completed jobs for a labor
  Future<List<Job>> getCompletedJobs(String laborId) async {
    try {
      final query =
          await _firestore
              .collection('jobs')
              .where('assignedTo', isEqualTo: laborId)
              .where('status', isEqualTo: 'completed')
              .get();
      return query.docs.map((doc) => Job.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch completed jobs: $e');
    }
  }

  // Get available cities
  Future<List<String>> getCities() async {
    try {
      final snapshot = await _firestore.collection('cities').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to fetch cities: $e');
    }
  }

  // Get areas for a city
  Future<List<String>> getAreas(String city) async {
    try {
      if (city.isEmpty) throw Exception('City cannot be empty');
      final doc = await _firestore.collection('cities').doc(city).get();
      if (doc.exists && doc.data() != null && doc.data()!['areas'] != null) {
        return List<String>.from(doc.data()!['areas']);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch areas: $e');
    }
  }
}
