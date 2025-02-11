import 'package:flutter/material.dart';
import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';

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

  /// ✅ Build the **User Rank Card** Widget
  Widget buildUserRankCard(Map<String, dynamic>? userRank) {
    if (userRank == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.purpleAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            "Your Rank",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          const SizedBox(height: 5),
          Text(
            "#${userRank["rank"]} - ${userRank["username"]}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text("Points: ${userRank["points"]}"),
        ],
      ),
    );
  }

  /// ✅ Build the **Leaderboard List** Widget
  Widget buildLeaderboardList(List<Map<String, dynamic>> leaderboard, String? currentUsername) {
    return Expanded(
      child: ListView.builder(
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final user = leaderboard[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purpleAccent,
              child: Text("${index + 1}"), // ✅ Show ranking
            ),
            title: Text(user["username"] ?? "Unknown"),
            subtitle: Text("Points: ${user["points"] ?? 0}"),
            tileColor: (currentUsername != null && user["username"] == currentUsername)
                ? Colors.yellow.withOpacity(0.3) // ✅ Highlight current user in the list
                : null,
          );
        },
      ),
    );
  }

  /// ✅ Combine User Rank & Leaderboard List
  Widget buildLeaderboardWidget() {
    return FutureBuilder<Map<String, dynamic>>(
      future: getLeaderboard(), // ✅ Fetch leaderboard & user rank
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // ✅ Show loading
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!["leaderboard"] == null) {
          return const Center(child: Text("No leaderboard data available.")); // ✅ Handle errors
        }

        final leaderboard = List<Map<String, dynamic>>.from(snapshot.data!["leaderboard"]);
        final userRank = snapshot.data!["user_rank"]; // ✅ Get user rank if available
        final currentUsername = userRank != null ? userRank["username"] : null;

        return Column(
          children: [
            buildUserRankCard(userRank), // ✅ Show User Rank
            buildLeaderboardList(leaderboard, currentUsername), // ✅ Show Leaderboard List
          ],
        );
      },
    );
  }
}
