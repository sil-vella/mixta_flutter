import 'package:flutter/material.dart';
import '../../../../../utils/consts/theme_consts.dart';

class FactBox extends StatelessWidget {
  final List<String>? facts;

  const FactBox({
    Key? key,
    required this.facts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.accentColor, // ✅ Gold Background
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4, // ✅ Limits height to 40% of screen
        ),
        child: SingleChildScrollView(
          child: Text(
            facts?.join("\n- ") ?? "No facts available",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black, // ✅ Black Text
            ),
          ),
        ),
      ),
    );
  }
}
