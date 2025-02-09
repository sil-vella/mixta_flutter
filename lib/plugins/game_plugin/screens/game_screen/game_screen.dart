import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/00_base/screen_base.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../modules/game_play_module/game_play_module.dart';
import 'components/fact_box.dart';
import 'components/feedback_message.dart';
import 'components/game_image_grid.dart';

class GameScreen extends BaseScreen {
  const GameScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Guess The Actor!";
  }

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends BaseScreenState<GameScreen> {
  late final GamePlayModule gamePlayModule;
  bool _showFeedback = false; // ✅ Controls overlay visibility
  String _feedbackText = ""; // ✅ Stores feedback message
  Timer? _feedbackTimer;
  int _level = 1;
  int _points = 0;

  final ServicesManager _servicesManager = ServicesManager();

  @override
  void initState() {
    super.initState();
    Logger().info("Initializing GameScreen...");

    // ✅ Retrieve GamePlayModule from ModuleManager
    gamePlayModule = moduleManager.getModule('game_play_module') ?? GamePlayModule();

    // ✅ Fetch question data
    gamePlayModule.RoundInit(() {
      setState(() {});
    });

    // ✅ Load level and points
    _loadLevelAndPoints();
  }

  /// ✅ Load level and points from SharedPreferences
  Future<void> _loadLevelAndPoints() async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      Logger().error('SharedPreferences service not available.');
      return;
    }

    final int level = await sharedPref.callServiceMethod('getInt', ['level']) ?? 1;
    final int points = await sharedPref.callServiceMethod('getInt', ['points']) ?? 0;

    setState(() {
      _level = level;
      _points = points;
    });

    Logger().info("📊 Loaded Level: $_level | Points: $_points");
  }

  /// ✅ Reusable function to update feedback state
  void _updateFeedbackState({required bool showFeedback, String feedbackText = ""}) {
    setState(() {
      _showFeedback = showFeedback;
      _feedbackText = feedbackText;
    });

    // ✅ Hide feedback after 2 seconds if needed
    if (showFeedback) {
      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _updateFeedbackState(showFeedback: false);
          gamePlayModule.RoundInit(() {
            setState(() {});
          });
        }
      });
    }
  }

  /// ✅ Handles answer selection, updates points
  void _handleAnswer(String selectedImage) {
    gamePlayModule.checkAnswer(selectedImage, () {
      _updateFeedbackState(showFeedback: true, feedbackText: gamePlayModule.feedbackMessage);
      _loadLevelAndPoints(); // Refresh level and points after update
    });
  }

  /// ✅ Manually close feedback
  void _closeFeedback() {
    _updateFeedbackState(showFeedback: false);
    _feedbackTimer?.cancel();
    gamePlayModule.RoundInit(() {
      setState(() {});
    });
  }

  @override
  Widget buildContent(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // ✅ Top bar showing Level and Points
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "⭐ Level: $_level",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "🏆 Points: $_points",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: gamePlayModule.isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ Image Grid
                    GameImageGrid(
                      imageOptions: gamePlayModule.imageOptions.map((e) => e.toString()).toList(),
                      onImageTap: _handleAnswer,
                    ),

                    const SizedBox(height: 20),

                    // ✅ Fact Box
                    FactBox(
                      facts: (gamePlayModule.question?['facts'] as List<dynamic>?)
                          ?.map((e) => e.toString())
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ✅ Full-Screen Feedback Overlay (Only when _showFeedback is true)
        if (_showFeedback)
          Positioned.fill(
            child: FeedbackMessage(
              feedback: _feedbackText,
              onClose: _closeFeedback, // ✅ Pass close method
            ),
          ),
      ],
    );
  }
}
