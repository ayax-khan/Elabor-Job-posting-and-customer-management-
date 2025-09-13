import 'package:elabor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JobCompletionDialog extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String laborName;
  final String customerUid;

  const JobCompletionDialog({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.laborName,
    required this.customerUid,
  });

  @override
  State<JobCompletionDialog> createState() => _JobCompletionDialogState();
}

class _JobCompletionDialogState extends State<JobCompletionDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  Future<void> _confirmCompletion(bool isCompleted) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.confirmJobCompletion(
        widget.jobId,
        widget.customerUid,
        isCompleted,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCompleted
                  ? 'Job marked as completed successfully!'
                  : 'Job marked as not completed. The labor has been notified.',
            ),
            backgroundColor: isCompleted ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_outline,
              color: Colors.blue.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Job Completion Confirmation',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job: ${widget.jobTitle}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Labor: ${widget.laborName}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Has this labor completed the job to your satisfaction?',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your decision will determine if the job is added to the labor\'s completed jobs list.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          TextButton(
            onPressed: () => _confirmCompletion(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _confirmCompletion(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
