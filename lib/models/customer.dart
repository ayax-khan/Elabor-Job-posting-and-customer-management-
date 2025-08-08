import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String uid;
  final String name;
  final String phoneNumber;
  final String email;
  final String? profilePhotoUrl;

  Customer({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.profilePhotoUrl,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      uid: doc.id,
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      profilePhotoUrl: data['profilePhotoUrl'],
    );
  }
}
