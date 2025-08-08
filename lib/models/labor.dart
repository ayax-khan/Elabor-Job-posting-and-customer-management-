import 'package:cloud_firestore/cloud_firestore.dart';

class Labor {
  final String uid;
  final String fullName;
  final String cnic;
  final String? dob; // Made nullable
  final String gender;
  final String contactNumber;
  final String address;
  final String city;
  final String area;
  final String email;
  final List<String> skills;
  final int experience;
  final List<String> languages;
  final String availability;
  final double expectedWage;
  final String? profilePhotoUrl;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String? skillProofUrl;

  Labor({
    required this.uid,
    required this.fullName,
    required this.cnic,
    this.dob, // Nullable
    required this.gender,
    required this.contactNumber,
    required this.address,
    required this.city,
    required this.area,
    required this.email,
    required this.skills,
    required this.experience,
    required this.languages,
    required this.availability,
    required this.expectedWage,
    this.profilePhotoUrl,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.skillProofUrl,
  });

  factory Labor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Labor(
      uid: doc.id,
      fullName: data['fullName'] ?? '', // Default to empty string
      cnic: data['cnic'] ?? '',
      dob: data['dob'], // Nullable
      gender: data['gender'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      area: data['area'] ?? '',
      email: data['email'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      experience: data['experience'] ?? 0,
      languages: List<String>.from(data['languages'] ?? []),
      availability: data['availability'] ?? '',
      expectedWage: (data['expectedWage'] as num?)?.toDouble() ?? 0.0,
      profilePhotoUrl: data['profilePhotoUrl'],
      cnicFrontUrl: data['cnicFrontUrl'],
      cnicBackUrl: data['cnicBackUrl'],
      skillProofUrl: data['skillProofUrl'],
    );
  }
}
