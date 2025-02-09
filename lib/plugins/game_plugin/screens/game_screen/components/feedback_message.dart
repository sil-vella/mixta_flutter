import 'package:flutter/material.dart';
import '../../../../../utils/consts/theme_consts.dart';

class FeedbackMessage extends StatelessWidget {
  final String feedback;
  final VoidCallback onClose; // ✅ Callback to close feedback

  const FeedbackMessage({
    Key? key,
    required this.feedback,
    required this.onClose, // ✅ Required close function
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8), // ✅ Dark background overlay
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ Keep the content centered
        children: [
          // ✅ Feedback text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              feedback,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: feedback.contains("Correct") ? AppColors.accentColor : Colors.redAccent,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Close Button (Below Text)
          ElevatedButton(
            onPressed: onClose, // ✅ Call onClose method
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor, // ✅ Themed button
              foregroundColor: Colors.black, // ✅ Contrast text
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // ✅ Rounded corners
              ),
            ),
            child: const Text(
              "Close",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
