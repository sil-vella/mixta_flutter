import 'package:flutter/material.dart';

class TimerBar extends StatelessWidget {
  final double remainingTime;
  final double totalDuration;

  const TimerBar({
    Key? key,
    required this.remainingTime,
    required this.totalDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = (remainingTime / totalDuration).clamp(0.0, 1.0);
    double fullWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // ✅ Transparent background with red border
        Container(
          width: fullWidth,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.transparent, // Fully transparent background
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.red, width: 2), // Red border
          ),
        ),
        // ✅ Shrinking red timer bar
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight, // Shrinks from right to left
            child: Container(
              width: fullWidth * progress, // Shrinks dynamically
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red, // Solid red timer bar
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
