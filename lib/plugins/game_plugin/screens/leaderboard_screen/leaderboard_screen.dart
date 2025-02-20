import 'package:flutter/material.dart';
import 'package:mixta_guess_who/core/managers/module_manager.dart';
import '../../../../core/00_base/screen_base.dart';
import '../../../../tools/logging/logger.dart';
import '../../../../utils/consts/theme_consts.dart';
import '../../modules/leaderboard_module/leaderboard_module.dart';

class LeaderboardScreen extends BaseScreen {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Leaderboard";
  }

  @override
  LeaderboardScreenState createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends BaseScreenState<LeaderboardScreen> {
  final LeaderboardModule _leaderboardModule = LeaderboardModule();

  @override
  void initState() {
    super.initState();
    Logger().info("📊 Initializing LeaderboardScreen...");
  }

  @override
  Widget buildContent(BuildContext context) {
    return Stack(
      children: [
        // ✅ Background Gradient
        Container(
          color: AppColors.scaffoldBackgroundColor, // ✅ Apply theme background
        ),


        // ✅ Leaderboard Title
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: const Text(
              "🏆 Leaderboard",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // ✅ Display Leaderboard Widget
        Positioned.fill(
          top: 80,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _leaderboardModule.buildLeaderboardWidget(),
          ),
        ),
      ],
    );
  }
}
