import 'package:flutter/material.dart';
import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../../../utils/consts/theme_consts.dart'; // ✅ Import Theme

class LeaderboardModule extends ModuleBase {
  final Logger logger = Logger();
  final ServicesManager servicesManager = ServicesManager();
  final ModuleManager moduleManager = ModuleManager();

  static LeaderboardModule? _instance;

  /// Private constructor for singleton pattern
  LeaderboardModule._internal();

  /// Factory method to provide a singleton instance
  factory LeaderboardModule() {
    _instance ??= LeaderboardModule._internal();
    return _instance!;
  }

  /// ✅ Fetch leaderboard data from backend
  Future<Map<String, dynamic>> getLeaderboard() async {
    final connectionModule = moduleManager.getModule('connection_module');
    final sharedPrefService = servicesManager.getService('shared_pref');

    if (connectionModule == null) {
      logger.error("❌ ConnectionModule not found!");
      return {};
    }

    if (sharedPrefService == null) {
      logger.error("❌ SharedPrefManager not found!");
      return {};
    }

    try {
      // ✅ Retrieve user's email from SharedPreferences (if logged in)
      final userEmail = await sharedPrefService.callServiceMethod('getString', ['email']);
      final queryParams = userEmail != null ? "?email=$userEmail" : "";

      logger.info("⚡ Fetching leaderboard data from `/get-leaderboard$queryParams`...");

      // ✅ Send GET request with email (if available)
      final response = await connectionModule.callMethod(
        'sendGetRequest',
        ["/get-leaderboard$queryParams"],
      );

      logger.info("✅ Leaderboard response: $response");

      if (response != null && response.containsKey("leaderboard")) {
        return {
          "leaderboard": List<Map<String, dynamic>>.from(response["leaderboard"]),
          "user_rank": response["user_rank"] // ✅ User rank if available
        };
      } else {
        logger.error("❌ Failed to retrieve leaderboard data.");
        return {};
      }
    } catch (e) {
      logger.error("❌ Error fetching leaderboard: $e");
      return {};
    }
  }

  /// ✅ **User Rank Card (Styled)**
  Widget buildUserRankCard(Map<String, dynamic>? userRank) {
    if (userRank == null) return const SizedBox.shrink();

    return Card(
      color: AppColors.primaryColor, // ✅ Consistent dark theme
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: AppPadding.defaultPadding,
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          children: [
            Text(
              "🏆 Your Rank",
              style: AppTextStyles.headingSmall(color: AppColors.accentColor),
            ),
            const SizedBox(height: 8),
            Text(
              "#${userRank["rank"]} - ${userRank["username"]}",
              style: AppTextStyles.bodyLarge,
            ),
            Text(
              "⭐ Points: ${userRank["points"]}",
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ **Leaderboard List (Styled)**
  Widget buildLeaderboardList(List<Map<String, dynamic>> leaderboard, String? currentUsername) {
    return Expanded(
      child: ListView.builder(
        itemCount: leaderboard.length,
        padding: AppPadding.defaultPadding,
        itemBuilder: (context, index) {
          final user = leaderboard[index];

          return Card(
            color: (currentUsername != null && user["username"] == currentUsername)
                ? AppColors.accentColor.withOpacity(0.3) // ✅ Highlight current user
                : AppColors.primaryColor, // ✅ Default color
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accentColor,
                child: Text(
                  "${index + 1}",
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              title: Text(
                user["username"] ?? "Unknown",
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                "⭐ Points: ${user["points"] ?? 0}",
                style: AppTextStyles.bodyMedium,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildLeaderboardWidget() {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor, // ✅ Ensure solid background
      body: FutureBuilder<Map<String, dynamic>>(

        future: getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!["leaderboard"] == null) {
            return const Center(
              child: Text("No leaderboard data available.", style: AppTextStyles.bodyLarge),
            );
          }

          final leaderboard = List<Map<String, dynamic>>.from(snapshot.data!["leaderboard"]);
          final userRank = snapshot.data!["user_rank"];
          final currentUsername = userRank != null ? userRank["username"] : null;

          return Column(
            children: [
              buildUserRankCard(userRank),
              buildLeaderboardList(leaderboard, currentUsername),
            ],
          );
        },
      ),
    );
  }

}
