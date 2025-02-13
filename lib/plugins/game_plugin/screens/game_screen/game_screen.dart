import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../../core/00_base/screen_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../core/managers/state_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../../adverts_plugin/modules/admobs/rewarded/rewarded_ad.dart';
import '../../../main_plugin/modules/main_helper_module/main_helper_module.dart';
import '../../modules/game_play_module/config/gameplaymodule_config.dart';
import '../../modules/game_play_module/game_play_module.dart';
import 'components/fact_box.dart';
import 'components/feedback_message.dart';
import 'components/game_image_grid.dart';
import 'components/timer_component.dart';

class GameScreen extends BaseScreen {
  const GameScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Guess Who";
  }

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends BaseScreenState<GameScreen> {
  late final GamePlayModule gamePlayModule;
  bool _showFeedback = false;
  String _feedbackText = "";
  String? _selectedImageUrl;
  Timer? _feedbackTimer;
  int _level = 1;
  int _points = 0;
  String _backgroundImage = "";
  final ServicesManager _servicesManager = ServicesManager();
  final Random _random = Random();

  Set<String> fadedImages = {}; // ✅ Tracks faded images

  @override
  void initState() {
    super.initState();
    Logger().info("Initializing GameScreen...");
    gamePlayModule = moduleManager.getModule('game_play_module') ?? GamePlayModule();
    _initializeGame();
    _loadLevelAndPoints();
  }

  /// ✅ Handles "Help" button click with Rewarded Ad
  void _useHelp() {
    final rewardedAdModule = ModuleManager().getModule<RewardedAdModule>('admobs_rewarded_ad_module');
    final mainHelper = ModuleManager().getModule<MainHelperModule>('main_helper_module');

    if (rewardedAdModule != null && mainHelper != null) {
      mainHelper.pauseTimer(); // ✅ Pause timer when ad starts

      rewardedAdModule.showAd([
            () {
          _fadeOutIncorrectImage(); // ✅ Only fade image after reward, NOT resume timer here
        },
            () {
          // ✅ Resume timer only after ad is fully dismissed
          Future.delayed(const Duration(milliseconds: 500), () {
            mainHelper.resumeTimer(() {
              Logger().info("⏳ Timer resumed after ad was closed.");
            });
          });
        }
      ]);
    } else {
      Logger().info("❌ RewardedAdModule or MainHelperModule not found!");
    }
  }

  /// ✅ Fades out a random incorrect image (timer will resume from `onAdDismissed`)
  void _fadeOutIncorrectImage() {
    if (_correctAnswer == null) return; // ✅ Ensure we have a correct answer

    List<String> incorrectImages = gamePlayModule.imageOptions
        .where((img) => img != _correctAnswer && !fadedImages.contains(img)) // ✅ Remove only incorrect images
        .toList();

    if (incorrectImages.isNotEmpty) {
      setState(() {
        String fadedImage = incorrectImages[_random.nextInt(incorrectImages.length)]; // ✅ Select a random incorrect image
        fadedImages.add(fadedImage); // ✅ Add it to the faded set
      });

      Logger().info("🚫 An incorrect image has been faded out.");
    }
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

  /// ✅ Initializes game and updates the random background
  void _initializeGame() {
    _setRandomBackground();

    gamePlayModule.roundInit(() {
      setState(() {
        _correctAnswer = gamePlayModule.question?['image_url']; // ✅ Fetch correct answer
        fadedImages.clear(); // ✅ Reset faded images each round
      });
    });

    // ✅ Set Timer - now correctly passes context and triggers _handleAnswer when time is up
    gamePlayModule.setTimer(() {
      _handleAnswer("", timeUp: true);
    });
  }



  String? _correctAnswer; // ✅ Stores the correct answer dynamically

  void _handleAnswer(String selectedImage, {bool timeUp = false}) {
    setState(() {
      _selectedImageUrl = selectedImage;
    });

    gamePlayModule.checkAnswer(selectedImage, () {
      setState(() {
        _correctAnswer = selectedImage; // ✅ Store the correct image when the user picks correctly
      });

      _updateFeedbackState(
        showFeedback: true,
        feedbackText: gamePlayModule.feedbackMessage,
      );

      _loadLevelAndPoints(); // ✅ Refresh level and points after update
    }, timeUp: timeUp);
  }


  /// ✅ Select a new random background
  void _setRandomBackground() {
    setState(() {
      _backgroundImage = MainHelperModule.getRandomBackground();
    });
    Logger().info("🎨 New Background: $_backgroundImage");
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
          _closeFeedback();
        }
      });
    }
  }

  /// ✅ Manually close feedback and reset the game + background
  void _closeFeedback() {
    _updateFeedbackState(showFeedback: false);
    _feedbackTimer?.cancel();
    _initializeGame(); // ✅ Reset game and change background
    setState(() {
      _selectedImageUrl = null; // ✅ Reset the selected image
    });
  }

  @override
  Widget buildContent(BuildContext context) {
    return Stack(
      children: [
        // ✅ Background Image
        Positioned.fill(
          child: _backgroundImage.isNotEmpty
              ? Image.asset(_backgroundImage, fit: BoxFit.cover)
              : Container(color: Colors.black),
        ),

        SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Top bar with Level, TimerBar, and Points
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("⭐ Level: $_level",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("🏆 Points: $_points",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Consumer<StateManager>(
                      builder: (context, stateManager, child) {
                        final timerState =
                            stateManager.getPluginState<Map<String, dynamic>>("game_timer") ?? {};
                        final isRunning = timerState["isRunning"] ?? false;
                        final duration = (timerState["duration"] ?? 0).toDouble();
                        final int currentLevel = _level > 0 ? _level : 1;
                        final double levelTimer =
                        (GamePlayConfig.levelTimers[currentLevel] ?? 10).toDouble();
                        return isRunning
                            ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: TimerBar(remainingTime: duration, totalDuration: levelTimer),
                          ),
                        )
                            : const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),

              // ✅ Image Grid with Fading Effect
              GameImageGrid(
                imageOptions: gamePlayModule.imageOptions.map((e) => e.toString()).toList(),
                onImageTap: _handleAnswer,
                fadedImages: fadedImages, // ✅ Pass faded images to disable them
              ),

              const SizedBox(height: 20),

              // ✅ Help Button (Center-aligned)
              ElevatedButton(
                onPressed: _useHelp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: const Text("💡 Use Help", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 20),

              // ✅ Fact Box (Scrollable)
              FactBox(
                facts: (gamePlayModule.question?['facts'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList(),
              ),
            ],
          ),
        ),

        // ✅ Full-Screen Feedback Overlay (Only when _showFeedback is true)
        if (_showFeedback)
          Positioned.fill(
            child: FeedbackMessage(
              feedback: _feedbackText,
              onClose: _closeFeedback,
              selectedImageUrl: _selectedImageUrl,
            ),
          ),
      ],
    );
  }
}
