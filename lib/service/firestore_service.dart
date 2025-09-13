import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/labor.dart';
import '../models/customer.dart';
import '../models/job.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save user roles
  Future<void> addUserRole(String uid, String role) async {
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
      await addUserRole(uid, 'labor');
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
      await addUserRole(uid, 'customer');
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

        // Create notification for new comment, only for the customer
        final jobTitle = jobDoc.data()?['title'] ?? 'your job post';
        if (customerUid != laborId) {
          // Ensure customer is not the labor commenting
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

      // Create notification for labor being hired, only for the labor
      final jobDoc = await _firestore.collection("jobs").doc(jobId).get();
      final jobTitle = jobDoc.data()?["title"] ?? "a job";
      final customerUid = jobDoc.data()?["postedBy"] ?? "";

      await createNotification(
        recipientId: laborId,
        senderId:
            customerUid, // The customer is the sender of this notification
        type: "laborHired",
        title: "Congratulations! You\"ve been hired",
        message: "You have been hired for the job: $jobTitle",
        relatedPostId: jobId,
        additionalData: {"jobTitle": jobTitle, "jobId": jobId},
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
              .where('hiredLaborId', isEqualTo: laborId)
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
              .where('hiredLaborId', isEqualTo: laborId)
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
      // Check if conversation already exists with participants in order (userId1, userId2)
      final conversationQuery =
          await _firestore
              .collection('conversations')
              .where('participants', isEqualTo: [userId1, userId2])
              .limit(1)
              .get();

      if (conversationQuery.docs.isNotEmpty) {
        return conversationQuery.docs.first.id;
      }

      // Check for conversation with reversed participants (userId2, userId1)
      final reversedConversationQuery =
          await _firestore
              .collection('conversations')
              .where('participants', isEqualTo: [userId2, userId1])
              .limit(1)
              .get();

      if (reversedConversationQuery.docs.isNotEmpty) {
        return reversedConversationQuery.docs.first.id;
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

        // Add message to subcollection
        transaction.set(conversationRef.collection('messages').doc(), {
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      });

      // Create notification for the receiver
      await createNotification(
        recipientId: receiverId,
        senderId: senderId,
        type: 'newMessage',
        title: 'New Message',
        message: content,
        relatedChatId: conversationId,
        additionalData: {
          'senderId': senderId,
          'receiverId': receiverId,
          'conversationId': conversationId,
        },
      );
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
          'contactNumber': data['contactNumber'],
          'phoneNumber': data['contactNumber'],
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
          'contactNumber': data['phoneNumber'],
          'phoneNumber': data['phoneNumber'],
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
        .where('type', whereNotIn: ['newMessage', 'chat'])
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
              .where('type', whereNotIn: ['newMessage', 'chat'])
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

      // Create notification for customer about job completion, only if customer is not the labor
      if (customerUid != laborId) {
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
      }
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

          // Create notification for labor about job completion confirmation
          final laborId = jobData['hiredLaborId'] as String?;
          final jobTitle = jobData['title'] ?? 'a job';
          if (laborId != null) {
            await createNotification(
              recipientId: laborId,
              senderId: customerUid,
              type: 'jobConfirmed',
              title: 'Job Confirmed',
              message:
                  'The customer has confirmed the completion of "$jobTitle".',
              relatedPostId: jobId,
              additionalData: {'jobTitle': jobTitle, 'jobId': jobId},
            );
          }
        } else {
          // Mark job as pending (customer rejected completion)
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

          // Create notification for labor about job completion rejection
          final laborId = jobData['hiredLaborId'] as String?;
          final jobTitle = jobData['title'] ?? 'a job';
          if (laborId != null) {
            await createNotification(
              recipientId: laborId,
              senderId: customerUid,
              type: 'jobRejected',
              title: 'Job Completion Rejected',
              message:
                  'The customer has rejected the completion of "$jobTitle". Please contact the customer for more details.',
              relatedPostId: jobId,
              additionalData: {'jobTitle': jobTitle, 'jobId': jobId},
            );
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to confirm job completion: $e');
    }
  }

  // Get labor's current hired job
  Future<Job?> getLaborCurrentHiredJob(String laborId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('jobs')
              .where('hiredLaborId', isEqualTo: laborId)
              .where('status', whereIn: ['hired', 'pending_completion'])
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Job.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get labor current hired job: $e');
    }
  }

  // Get customer's current posted job
  Future<Job?> getCustomerCurrentPostedJob(String customerId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('jobs')
              .where('postedBy', isEqualTo: customerId)
              .where('status', whereIn: ['hired', 'pending_completion'])
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Job.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer current posted job: $e');
    }
  }

  // Get all jobs posted by a specific customer
  Stream<List<Job>> getJobsPostedByCustomer(String customerId) {
    return _firestore
        .collection('jobs')
        .where('postedBy', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList(),
        );
  }

  // Get all jobs a labor has commented on
  Stream<List<Job>> getJobsLaborCommentedOn(String laborId) {
    return _firestore
        .collection('jobs')
        .where(
          'comments.laborId',
          arrayContains: laborId,
        ) // This query won't work directly as 'comments' is a subcollection
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList(),
        );
  }

  // Get all jobs a labor has been hired for
  Stream<List<Job>> getJobsLaborHiredFor(String laborId) {
    return _firestore
        .collection('jobs')
        .where('hiredLaborId', isEqualTo: laborId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList(),
        );
  }

  // Get a single job by ID
  Future<Job?> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (doc.exists) {
        return Job.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get job by ID: $e');
    }
  }

  // Update job status
  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update job status: $e');
    }
  }

  // Get all labors (for search/browse)
  Stream<List<Labor>> getAllLabors() {
    return _firestore
        .collection('labors')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Labor.fromFirestore(doc)).toList(),
        );
  }

  // Get a single labor by ID
  Future<Labor?> getLaborById(String laborId) async {
    try {
      final doc = await _firestore.collection('labors').doc(laborId).get();
      if (doc.exists) {
        return Labor.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get labor by ID: $e');
    }
  }

  // Get a single customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(customerId)
              .collection('customerProfile')
              .doc('data')
              .get();
      if (doc.exists) {
        return Customer.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer by ID: $e');
    }
  }

  // Get all customers (if needed, use with caution for large datasets)
  Stream<List<Customer>> getAllCustomers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
        );
  }

  // Get labor's average rating (placeholder)
  Future<double> getLaborAverageRating(String laborId) async {
    // Implement actual rating calculation based on reviews/feedback
    return 4.5; // Placeholder
  }

  // Get labor's total jobs completed (placeholder)
  Future<int> getLaborTotalJobsCompleted(String laborId) async {
    // Implement actual count based on completed jobs
    return 10; // Placeholder
  }

  // Update labor profile
  Future<void> updateLaborProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('labors').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update labor profile: $e');
    }
  }

  // Update customer profile
  Future<void> updateCustomerProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('customerProfile')
          .doc('data')
          .update(data);
    } catch (e) {
      throw Exception('Failed to update customer profile: $e');
    }
  }

  // Delete user data (labor or customer)
  Future<void> deleteUserData(String uid, String role) async {
    try {
      if (role == 'labor') {
        await _firestore.collection('labors').doc(uid).delete();
      } else if (role == 'customer') {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('customerProfile')
            .doc('data')
            .delete();
      }
      // Optionally remove the role from the user's roles document
      final roleDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('roles')
          .doc('data');
      final doc = await roleDoc.get();
      if (doc.exists && doc.data() != null && doc.data()!['roles'] != null) {
        List<String> roles = List<String>.from(doc.data()!['roles']);
        roles.remove(role);
        await roleDoc.set({'roles': roles});
      }
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }
}
