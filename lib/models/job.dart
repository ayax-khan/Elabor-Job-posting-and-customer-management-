import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final String address;
  final String city;
  final String area;
  final String? imageUrl;
  final String postedBy;
  final DateTime createdAt;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.area,
    this.imageUrl,
    required this.postedBy,
    required this.createdAt,
  });

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      area: data['area'] ?? '',
      imageUrl: data['imageUrl'],
      postedBy: data['postedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
