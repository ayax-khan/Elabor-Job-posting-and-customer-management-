import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerChatScreen extends StatelessWidget {
  const CustomerChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.03,
          ),
          child: Column(
            children: [
              Text(
                'Messages',
                style: GoogleFonts.poppins(
                  fontSize: size.width * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Expanded(
                child: ListView.builder(
                  itemCount: 0, // Placeholder: Replace with actual chat data
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const CircleAvatar(),
                      title: Text('Chat $index', style: GoogleFonts.poppins()),
                      subtitle: Text(
                        'Last message...',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
