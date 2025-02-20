import 'package:flutter/material.dart';
import '../../../../core/00_base/screen_base.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../modules/function_helper_module/function_helper_module.dart';

class ProgressScreen extends BaseScreen {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Well Done!";
  }

  @override
  ProgressScreenState createState() => ProgressScreenState();
}

class ProgressScreenState extends BaseScreenState<ProgressScreen> {
  final Logger logger = Logger();
  final sharedPrefService = ServicesManager().getService('shared_pref');

  Map<String, dynamic> _categories = {};
  int _totalPoints = 0; // Track total points across categories
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  /// ✅ Fetch categories along with levels, points, and guessed names
  Future<void> _fetchCategories() async {
    if (sharedPrefService == null) return;

    List<String> cachedCategories = await sharedPrefService?.callServiceMethod('getStringList', ['available_categories']) ?? [];

    if (cachedCategories.isNotEmpty) {
      logger.info('📜 Loaded categories from SharedPreferences: $cachedCategories');

      Map<String, dynamic> categoryData = {};

      for (String category in cachedCategories) {
        int maxLevels = await sharedPrefService?.callServiceMethod('getInt', ['max_levels_$category']) ?? 1;
        int currentLevel = await sharedPrefService?.callServiceMethod('getInt', ['level_$category']) ?? 1;

        int categoryPoints = 0;
        int guessedNamesCount = 0;

        for (int level = 1; level <= maxLevels; level++) {
          int points = await sharedPrefService?.callServiceMethod('getInt', ['points_${category}_level$level']) ?? 1;
          List<String> guessedNames = await sharedPrefService?.callServiceMethod('getStringList', ['guessed_${category}_level$level']) ?? [];

          categoryPoints += points;
          guessedNamesCount += guessedNames.length;
        }

        categoryData[category] = {
          "level": currentLevel,
          "points": categoryPoints,
          "guessedNamesCount": guessedNamesCount,
        };

        logger.info("📊 Category: $category -> Level: $currentLevel, Points: $categoryPoints, Guessed: $guessedNamesCount");
      }

      // ✅ Use FunctionHelperModule to get the total points
      int totalPoints = await FunctionHelperModule().getTotalPoints();

      setState(() {
        _categories = categoryData;
        _totalPoints = totalPoints; // ✅ Now using the helper method
        _isLoading = false;
      });

      return;
    }

    logger.error('⚠️ No categories found in SharedPreferences.');
    setState(() => _isLoading = false);
  }

  /// ✅ Format category name (Replace `_` with space & capitalize first letter)
  String _formatCategoryName(String category) {
    return category.replaceAll("_", " ").splitMapJoin(
      RegExp(r'(\w+)'),
      onMatch: (m) => m[0]![0].toUpperCase() + m[0]!.substring(1).toLowerCase(),
    );
  }

  /// ✅ UI for displaying category progress
  Widget _buildCategoryProgress() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return const Center(child: Text("No category progress found.", style: TextStyle(fontSize: 18)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Display total points at the top
        Card(
          margin: const EdgeInsets.all(16),
          color: Colors.blueAccent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                "🏆 Total Points: $_totalPoints",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),

        // ✅ Category List
        Expanded(
          child: ListView(
            children: _categories.entries.map((entry) {
              final category = entry.key;
              final data = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    _formatCategoryName(category), // Format category name
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "🔹 Level: ${data["level"]}\n⭐ Points: ${data["points"]}\n🎯 Guessed Names: ${data["guessedNamesCount"]}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Category Progress")),
      body: _buildCategoryProgress(),
    );
  }
}
