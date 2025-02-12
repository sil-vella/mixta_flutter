import 'package:flutter/material.dart';

class TimerBar extends StatefulWidget {
  final int durationInSeconds;

  const TimerBar({Key? key, required this.durationInSeconds}) : super(key: key);

  @override
  _TimerBarState createState() => _TimerBarState();
}

class _TimerBarState extends State<TimerBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // ✅ Initialize AnimationController with specified duration
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationInSeconds),
    )..forward(); // Start the animation immediately

    // ✅ Create a width animation that decreases from 100% to 0%
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ Clean up resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: MediaQuery.of(context).size.width * _animation.value, // ✅ Decreasing width
          height: 10, // ✅ Fixed height
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purpleAccent, Colors.deepPurpleAccent], // ✅ Glow Effect
            ),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.8),
                blurRadius: 10,
                spreadRadius: 2,
                offset: Offset(0, 0),
              ),
            ],
          ),
        );
      },
    );
  }
}
