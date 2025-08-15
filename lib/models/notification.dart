import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  newMessage,
  newComment,
  laborHired,
}

class AppNotification {
  final String id;
  final String recipientId;
  final String senderId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedChatId;
  final String? relatedPostId;
  final Map<String, dynamic>? additionalData;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.relatedChatId,
    this.relatedPostId,
    this.additionalData,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: _parseNotificationType(data['type']),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      relatedChatId: data['relatedChatId'],
      relatedPostId: data['relatedPostId'],
      additionalData: data['additionalData'] != null 
          ? Map<String, dynamic>.from(data['additionalData'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'relatedChatId': relatedChatId,
      'relatedPostId': relatedPostId,
      'additionalData': additionalData,
    };
  }

  static NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'newMessage':
        return NotificationType.newMessage;
      case 'newComment':
        return NotificationType.newComment;
      case 'laborHired':
        return NotificationType.laborHired;
      default:
        return NotificationType.newMessage;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.newComment:
        return 'New Comment';
      case NotificationType.laborHired:
        return 'Labor Hired';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.newComment:
        return Icons.comment;
      case NotificationType.laborHired:
        return Icons.work;
    }
  }
}

