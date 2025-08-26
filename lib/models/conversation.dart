import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final String lastMessageSenderId;
  final Map<String, int> unreadCounts;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.lastMessageSenderId,
    required this.unreadCounts,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final unreadCounts = Map<String, int>.from(data['unreadCounts'] ?? {});

    // Ensure unreadCounts is valid
    for (final participant in data['participants'] ?? []) {
      if (!unreadCounts.containsKey(participant)) {
        unreadCounts[participant] = 0;
      }
    }

    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp:
          (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCounts: unreadCounts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
    };
  }

  int getUnreadCountForUser(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (participant) => participant != currentUserId,
      orElse: () => '',
    );
  }
}
