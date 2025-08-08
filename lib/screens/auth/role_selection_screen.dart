import 'package:elabor/widgets/animated_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/firestore_service.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final bool isLabor;
  const RoleSelectionScreen({super.key, required this.isLabor});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLabor ? 'Join as Labor' : 'Join as Customer',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLabor
                    ? 'Ready to find jobs as a skilled labor?'
                    : 'Ready to post jobs and hire labor?',
                style: GoogleFonts.poppins(
                  fontSize: size.width * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.03),
              FutureBuilder<List<String>>(
                future:
                    FirebaseAuth.instance.currentUser != null
                        ? firestoreService.getUserRoles(
                          FirebaseAuth.instance.currentUser!.uid,
                        )
                        : Future.value([]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  final roles = snapshot.data ?? [];
                  if (roles.contains(isLabor ? 'labor' : 'customer')) {
                    return Text(
                      'You are already registered as a ${isLabor ? "labor" : "customer"}.',
                      style: GoogleFonts.poppins(
                        fontSize: size.width * 0.04,
                        color: Colors.red,
                      ),
                    );
                  }
                  return AnimatedButton(
                    text: 'Continue as ${isLabor ? "Labor" : "Customer"}',
                    color: isLabor ? Colors.blueAccent : Colors.greenAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(isLabor: isLabor),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
