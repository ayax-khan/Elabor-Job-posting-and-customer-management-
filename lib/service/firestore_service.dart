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

  // Delete a job post
  Future<void> deleteJobPost(String jobId, String customerUid) async {
    try {
      // Delete from main jobs collection
      await _firestore.collection('jobs').doc(jobId).delete();

      // Delete from customer's posts subcollection
      await _firestore
          .collection('users')
          .doc(customerUid)
          .collection('customerProfile')
          .doc('data')
          .collection('posts')
          .doc(jobId)
          .delete();

      // Delete all comments for this job
      final commentsSnapshot =
          await _firestore
              .collection('jobs')
              .doc(jobId)
              .collection('comments')
              .get();

      final batch = _firestore.batch();
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete job post: $e');
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
      // Check if job is already hired
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (jobDoc.exists && jobDoc.data()?['hiredLaborId'] != null) {
        throw Exception('This job has already been filled');
      }

      // Check comment count for this labor on this post
      final existingComments =
          await _firestore
              .collection('jobs')
              .doc(jobId)
              .collection('comments')
              .where('laborId', isEqualTo: laborId)
              .get();

      if (existingComments.docs.length >= 2) {
        throw Exception('You can only comment twice on each post');
      }

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
      final customerUid = jobDoc.data()?['postedBy'] as String?;
      if (customerUid != null) {
        await _firestore
            .collection('users')
            .doc(customerUid)
            .collection('postedJobs')
            .doc(jobId)
            .collection('comments')
            .add(commentData);

        // Create notification for new comment
        final jobTitle = jobDoc.data()?['title'] ?? 'your job post';
        await createNotification(
          recipientId: customerUid,
          senderId: laborId,
          type: 'newComment',
          title: 'New Comment',
          message:
              '$laborName commented on $jobTitle: ${comment.length > 50 ? '${comment.substring(0, 50)}...' : comment}',
          relatedPostId: jobId,
          additionalData: {'jobTitle': jobTitle, 'laborName': laborName},
        );
      }
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Hire a labor for a job post
  Future<void> hireLaborForJob(
    String jobId,
    String laborId,
    String laborName,
  ) async {
    try {
      final jobRef = _firestore.collection('jobs').doc(jobId);

      await _firestore.runTransaction((transaction) async {
        final jobDoc = await transaction.get(jobRef);

        if (!jobDoc.exists) {
          throw Exception('Job not found');
        }

        final jobData = jobDoc.data()!;
        if (jobData['hiredLaborId'] != null) {
          throw Exception('This job has already been filled');
        }

        // Update job with hired labor
        transaction.update(jobRef, {
          'hiredLaborId': laborId,
          'hiredLaborName': laborName,
          'status': 'hired',
          'hiredAt': FieldValue.serverTimestamp(),
        });

        // Also update in customer's posted jobs collection
        final customerUid = jobData['postedBy'] as String?;
        if (customerUid != null) {
          final customerJobRef = _firestore
              .collection('users')
              .doc(customerUid)
              .collection('customerProfile')
              .doc('data')
              .collection('posts')
              .doc(jobId);

          transaction.update(customerJobRef, {
            'hiredLaborId': laborId,
            'hiredLaborName': laborName,
            'status': 'hired',
            'hiredAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Create notification for labor being hired
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobTitle = jobDoc.data()?['title'] ?? 'a job';

      await createNotification(
        recipientId: laborId,
        senderId: jobDoc.data()?['postedBy'] ?? '',
        type: 'laborHired',
        title: 'Congratulations! You\'ve been hired',
        message: 'You have been hired for the job: $jobTitle',
        relatedPostId: jobId,
        additionalData: {'jobTitle': jobTitle, 'jobId': jobId},
      );
    } catch (e) {
      throw Exception('Failed to hire labor: $e');
    }
  }

  // Get labor comment count for a specific job
  Future<int> getLaborCommentCountForJob(String jobId, String laborId) async {
    try {
      final snapshot =
          await _firestore
              .collection("jobs")
              .doc(jobId)
              .collection("comments")
              .where("laborId", isEqualTo: laborId)
              .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error getting labor comment count: $e");
      return 0;
    }
  }

  // Get labor details for comment display
  Future<Map<String, dynamic>?> getLaborDetailsForComment(
    String laborId,
  ) async {
    try {
      final laborDoc = await _firestore.collection('labors').doc(laborId).get();
      if (laborDoc.exists) {
        final data = laborDoc.data()!;
        return {
          'uid': laborId,
          'fullName': data['fullName'] ?? 'Unknown Labor',
          'profilePhotoUrl': data['profilePhotoUrl'],
          'skills': List<String>.from(data['skills'] ?? []),
          'contactNumber': data['contactNumber'] ?? '',
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get labor details: $e');
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

  // Get completed jobs for a labor (returns Map for profile display)
  Future<List<Map<String, dynamic>>> getCompletedJobsForLabor(
    String laborId,
  ) async {
    try {
      final query =
          await _firestore
              .collection('jobs')
              .where('assignedTo', isEqualTo: laborId)
              .where('status', isEqualTo: 'completed')
              .orderBy('createdAt', descending: true)
              .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled Job',
          'description': data['description'] ?? 'No description available',
          'completedAt': data['completedAt'],
          'customerName': data['customerName'] ?? 'Unknown Customer',
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch completed jobs for labor: $e');
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

  // Chat-related methods

  // Get or create a conversation between two users
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    try {
      // Check if conversation already exists
      final existingConversation =
          await _firestore
              .collection('conversations')
              .where('participants', arrayContains: userId1)
              .get();

      for (var doc in existingConversation.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(userId2)) {
          return doc.id;
        }
      }

      // Create new conversation
      final conversationData = {
        'participants': [userId1, userId2],
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCounts': {userId1: 0, userId2: 0},
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('conversations')
          .add(conversationData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  // Send a message
  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String receiverId,
    String content,
  ) async {
    try {
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      await _firestore.runTransaction((transaction) async {
        final conversationDoc = await transaction.get(conversationRef);
        final conversationData = conversationDoc.data() ?? {};

        // Initialize unreadCounts if it doesn't exist or is empty
        Map<String, int> currentUnreadCounts = {};
        if (conversationData['unreadCounts'] != null &&
            conversationData['unreadCounts'] is Map) {
          currentUnreadCounts = Map<String, int>.from(
            conversationData['unreadCounts'],
          );
        }

        // Ensure both users have entries in unreadCounts
        currentUnreadCounts[senderId] = currentUnreadCounts[senderId] ?? 0;
        currentUnreadCounts[receiverId] = currentUnreadCounts[receiverId] ?? 0;

        // Increment unread count for receiver
        currentUnreadCounts[receiverId] = currentUnreadCounts[receiverId]! + 1;

        transaction.update(conversationRef, {
          'lastMessage': content,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': senderId,
          'unreadCounts': currentUnreadCounts,
        });
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages stream for a conversation
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  // Get conversations for a user
  Stream<List<Map<String, dynamic>>> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);

      await _firestore.runTransaction((transaction) async {
        final conversationDoc = await transaction.get(conversationRef);
        final currentUnreadCounts = Map<String, int>.from(
          conversationDoc.data()?['unreadCounts'] ?? {},
        );

        // Reset unread count for this user
        currentUnreadCounts[userId] = 0;

        transaction.update(conversationRef, {
          'unreadCounts': currentUnreadCounts,
        });
      });

      // Mark individual messages as read
      final messagesQuery =
          await _firestore
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .where('receiverId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      final batch = _firestore.batch();
      for (var doc in messagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get user details (name and profile picture) for chat display
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      // Try to get labor data first
      final laborDoc = await _firestore.collection('labors').doc(userId).get();
      if (laborDoc.exists) {
        final data = laborDoc.data()!;
        return {
          'name': data['fullName'] ?? 'Unknown User',
          'profilePictureUrl': data['profilePhotoUrl'],
          'type': 'labor',
        };
      }

      // Try to get customer data
      final customerDoc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('customerProfile')
              .doc('data')
              .get();
      if (customerDoc.exists) {
        final data = customerDoc.data()!;
        return {
          'name': data['name'] ?? 'Unknown User',
          'profilePictureUrl': data['profilePhotoUrl'],
          'type': 'customer',
        };
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }

  // Notification-related methods

  // Create a notification
  Future<void> createNotification({
    required String recipientId,
    required String senderId,
    required String type,
    required String title,
    required String message,
    String? relatedChatId,
    String? relatedPostId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notificationData = {
        'recipientId': recipientId,
        'senderId': senderId,
        'type': type,
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'relatedChatId': relatedChatId,
        'relatedPostId': relatedPostId,
        'additionalData': additionalData,
      };

      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get notifications for a user (excluding chat notifications)
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('type', whereNotIn: ['newMessage']) // Exclude chat notifications
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final notificationsQuery =
          await _firestore
              .collection('notifications')
              .where('recipientId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      final batch = _firestore.batch();
      for (var doc in notificationsQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Get unread notification count (excluding chat notifications)
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final unreadNotifications =
          await _firestore
              .collection('notifications')
              .where('recipientId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .where(
                'type',
                whereNotIn: ['newMessage'],
              ) // Exclude chat notifications
              .get();
      return unreadNotifications.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Job completion and cancellation methods

  // Mark job as completed by labor
  Future<void> markJobAsCompleted(String jobId, String laborId) async {
    try {
      final jobRef = _firestore.collection('jobs').doc(jobId);

      await _firestore.runTransaction((transaction) async {
        final jobDoc = await transaction.get(jobRef);

        if (!jobDoc.exists) {
          throw Exception('Job not found');
        }

        final jobData = jobDoc.data()!;
        if (jobData['hiredLaborId'] != laborId) {
          throw Exception('You are not hired for this job');
        }

        if (jobData['status'] == 'completed') {
          throw Exception('Job is already completed');
        }

        // Update job status to pending completion
        transaction.update(jobRef, {
          'status': 'pending_completion',
          'completedByLaborAt': FieldValue.serverTimestamp(),
        });

        // Also update in customer's posted jobs collection
        final customerUid = jobData['postedBy'] as String?;
        if (customerUid != null) {
          final customerJobRef = _firestore
              .collection('users')
              .doc(customerUid)
              .collection('customerProfile')
              .doc('data')
              .collection('posts')
              .doc(jobId);

          transaction.update(customerJobRef, {
            'status': 'pending_completion',
            'completedByLaborAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Create notification for customer about job completion
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobTitle = jobDoc.data()?['title'] ?? 'a job';
      final laborName = jobDoc.data()?['hiredLaborName'] ?? 'Labor';
      final customerUid = jobDoc.data()?['postedBy'] ?? '';

      await createNotification(
        recipientId: customerUid,
        senderId: laborId,
        type: 'jobCompleted',
        title: 'Job Completed',
        message:
            '$laborName has marked the job "$jobTitle" as completed. Please confirm if the work is satisfactory.',
        relatedPostId: jobId,
        additionalData: {
          'jobTitle': jobTitle,
          'laborName': laborName,
          'jobId': jobId,
          'requiresConfirmation': true,
        },
      );
    } catch (e) {
      throw Exception('Failed to mark job as completed: $e');
    }
  }

  // Cancel job by labor
  Future<void> cancelJob(String jobId, String laborId, String reason) async {
    try {
      final jobRef = _firestore.collection('jobs').doc(jobId);

      await _firestore.runTransaction((transaction) async {
        final jobDoc = await transaction.get(jobRef);

        if (!jobDoc.exists) {
          throw Exception('Job not found');
        }

        final jobData = jobDoc.data()!;
        if (jobData['hiredLaborId'] != laborId) {
          throw Exception('You are not hired for this job');
        }

        if (jobData['status'] == 'completed') {
          throw Exception('Cannot cancel a completed job');
        }

        // Update job status back to available
        transaction.update(jobRef, {
          'hiredLaborId': FieldValue.delete(),
          'hiredLaborName': FieldValue.delete(),
          'status': 'available',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancellationReason': reason,
        });

        // Also update in customer's posted jobs collection
        final customerUid = jobData['postedBy'] as String?;
        if (customerUid != null) {
          final customerJobRef = _firestore
              .collection('users')
              .doc(customerUid)
              .collection('customerProfile')
              .doc('data')
              .collection('posts')
              .doc(jobId);

          transaction.update(customerJobRef, {
            'hiredLaborId': FieldValue.delete(),
            'hiredLaborName': FieldValue.delete(),
            'status': 'available',
            'cancelledAt': FieldValue.serverTimestamp(),
            'cancellationReason': reason,
          });
        }
      });

      // Create notification for customer about job cancellation
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobTitle = jobDoc.data()?['title'] ?? 'a job';
      final laborName = jobDoc.data()?['hiredLaborName'] ?? 'Labor';
      final customerUid = jobDoc.data()?['postedBy'] ?? '';

      await createNotification(
        recipientId: customerUid,
        senderId: laborId,
        type: 'jobCancelled',
        title: 'Job Cancelled',
        message:
            '$laborName has cancelled the job "$jobTitle". Reason: $reason',
        relatedPostId: jobId,
        additionalData: {
          'jobTitle': jobTitle,
          'laborName': laborName,
          'jobId': jobId,
          'reason': reason,
        },
      );
    } catch (e) {
      throw Exception('Failed to cancel job: $e');
    }
  }

  // Confirm job completion by customer
  Future<void> confirmJobCompletion(
    String jobId,
    String customerUid,
    bool isCompleted,
  ) async {
    try {
      final jobRef = _firestore.collection('jobs').doc(jobId);

      await _firestore.runTransaction((transaction) async {
        final jobDoc = await transaction.get(jobRef);

        if (!jobDoc.exists) {
          throw Exception('Job not found');
        }

        final jobData = jobDoc.data()!;
        if (jobData['postedBy'] != customerUid) {
          throw Exception('You are not the owner of this job');
        }

        if (jobData['status'] != 'pending_completion') {
          throw Exception('Job is not pending completion');
        }

        if (isCompleted) {
          // Mark job as completed
          transaction.update(jobRef, {
            'status': 'completed',
            'confirmedByCustomerAt': FieldValue.serverTimestamp(),
          });

          // Also update in customer's posted jobs collection
          final customerJobRef = _firestore
              .collection('users')
              .doc(customerUid)
              .collection('customerProfile')
              .doc('data')
              .collection('posts')
              .doc(jobId);

          transaction.update(customerJobRef, {
            'status': 'completed',
            'confirmedByCustomerAt': FieldValue.serverTimestamp(),
          });

          // Add to labor's completed jobs
          final laborId = jobData['hiredLaborId'] as String;
          final completedJobData = {
            'jobId': jobId,
            'title': jobData['title'],
            'description': jobData['description'],
            'customerName': jobData['customerName'] ?? 'Unknown Customer',
            'completedAt': FieldValue.serverTimestamp(),
            'customerUid': customerUid,
          };

          transaction.set(
            _firestore
                .collection('labors')
                .doc(laborId)
                .collection('completedJobs')
                .doc(jobId),
            completedJobData,
          );
        } else {
          // Mark job as not completed, revert to hired status
          transaction.update(jobRef, {
            'status': 'hired',
            'completedByLaborAt': FieldValue.delete(),
          });

          // Also update in customer's posted jobs collection
          final customerJobRef = _firestore
              .collection('users')
              .doc(customerUid)
              .collection('customerProfile')
              .doc('data')
              .collection('posts')
              .doc(jobId);

          transaction.update(customerJobRef, {
            'status': 'hired',
            'completedByLaborAt': FieldValue.delete(),
          });
        }
      });

      // Create notification for labor about customer's decision
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobTitle = jobDoc.data()?['title'] ?? 'a job';
      final laborId = jobDoc.data()?['hiredLaborId'] ?? '';

      if (isCompleted) {
        await createNotification(
          recipientId: laborId,
          senderId: customerUid,
          type: 'jobConfirmed',
          title: 'Job Confirmed as Completed',
          message:
              'Great work! The customer has confirmed that you completed the job "$jobTitle" successfully.',
          relatedPostId: jobId,
          additionalData: {'jobTitle': jobTitle, 'jobId': jobId},
        );
      } else {
        await createNotification(
          recipientId: laborId,
          senderId: customerUid,
          type: 'jobNotConfirmed',
          title: 'Job Not Confirmed',
          message:
              'The customer has indicated that the job "$jobTitle" is not yet completed to their satisfaction.',
          relatedPostId: jobId,
          additionalData: {'jobTitle': jobTitle, 'jobId': jobId},
        );
      }
    } catch (e) {
      throw Exception('Failed to confirm job completion: $e');
    }
  }

  // Get job details for labor
  Future<Map<String, dynamic>?> getJobDetailsForLabor(String jobId) async {
    try {
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (jobDoc.exists) {
        final data = jobDoc.data()!;
        return {
          'id': jobId,
          'title': data['title'] ?? 'Untitled Job',
          'description': data['description'] ?? 'No description',
          'address': data['address'] ?? '',
          'city': data['city'] ?? '',
          'area': data['area'] ?? '',
          'status': data['status'] ?? 'available',
          'hiredLaborId': data['hiredLaborId'],
          'postedBy': data['postedBy'] ?? '',
          'createdAt': data['createdAt'],
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get job details: $e');
    }
  }

  // Get completed jobs for labor profile display
  Future<List<Map<String, dynamic>>> getCompletedJobsForLaborProfile(
    String laborId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('labors')
              .doc(laborId)
              .collection('completedJobs')
              .orderBy('completedAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled Job',
          'description': data['description'] ?? 'No description available',
          'customerName': data['customerName'] ?? 'Unknown Customer',
          'completedAt': data['completedAt'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch completed jobs for labor profile: $e');
    }
  }
}
