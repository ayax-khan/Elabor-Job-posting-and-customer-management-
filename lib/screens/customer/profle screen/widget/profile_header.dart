import 'package:elabor/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';

class ProfileHeader extends StatelessWidget {
  final Customer? customer;

  const ProfileHeader({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: size.width * 0.06,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: size.height * 0.03),
        FadeIn(
          child: CircleAvatar(
            radius: size.width * 0.15,
            backgroundImage:
                customer?.profilePhotoUrl != null
                    ? NetworkImage(customer!.profilePhotoUrl!)
                    : null,
            backgroundColor: Colors.grey[300],
          ),
        ),
        SizedBox(height: size.height * 0.02),
        FadeIn(
          delay: const Duration(milliseconds: 200),
          child: Text(
            customer?.name ?? 'No Name',
            style: GoogleFonts.poppins(
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FadeIn(
          delay: const Duration(milliseconds: 300),
          child: Text(
            customer?.phoneNumber ?? 'No Phone',
            style: GoogleFonts.poppins(fontSize: size.width * 0.04),
          ),
        ),
        FadeIn(
          delay: const Duration(milliseconds: 400),
          child: Text(
            FirebaseAuth.instance.currentUser?.email ?? 'No Email',
            style: GoogleFonts.poppins(fontSize: size.width * 0.04),
          ),
        ),
        SizedBox(height: size.height * 0.03),
        FadeIn(
          delay: const Duration(milliseconds: 500),
          child: ElevatedButton(
            onPressed: () {
              // Implement edit profile functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                vertical: size.height * 0.02,
                horizontal: size.width * 0.06,
              ),
            ),
            child: Text(
              'Edit Profile',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: size.width * 0.04,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
