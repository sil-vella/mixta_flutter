import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../../core/00_base/screen_base.dart';
import '../../../../core/managers/app_manager.dart';
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

  void _onImagesLoaded() {
    Logger().info("🖼️ ALL images loaded. Updating game state...");

    final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);
    stateManager.updatePluginState("game_round", {
      "imagesLoaded": true,
    }, force: true);
  }


  void _onFactsLoaded() {
    final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);

    stateManager.updatePluginState("game_round", {
      "factLoaded": true,
    }, force: true);
  }

  bool get _isOverlayVisible {
    return context.select<StateManager, bool>((stateManager) {
      final gameRoundState = stateManager.getPluginState<Map<String, dynamic>>("game_round") ?? {};
      return !(gameRoundState["imagesLoaded"] == true && gameRoundState["factLoaded"] == true);
    });
  }


  /// ✅ Handles "Help" button click with Rewarded Ad
  void _useHelp() {
    final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);
    final rewardedAdModule = ModuleManager().getModule<RewardedAdModule>('admobs_rewarded_ad_module');
    final mainHelper = ModuleManager().getModule<MainHelperModule>('main_helper_module');

    if (rewardedAdModule != null && mainHelper != null) {
      mainHelper.pauseTimer(); // ✅ Pause timer when ad starts
      // ✅ Update the game timer state before starting
      stateManager.updatePluginState("game_round", {
        "hint": true,
      });

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

  void _initializeGame() {
    Logger().info("🔄 Initializing new game round...");

    // ✅ Clear game state BEFORE setting new data
    setState(() {
      _correctAnswer = null;
      fadedImages.clear();
      _selectedImageUrl = null;
      gamePlayModule.imageOptions = []; // ✅ Ensure images reset
    });

    final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);

    // ✅ Defer state update to the next frame to avoid "setState during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stateManager.updatePluginState("game_round", {
        "hint": false,
        "imagesLoaded": false,
        "factLoaded": false,
      }, force: true);
    });

    // ✅ Clear the fact box content before loading new facts
    setState(() {
      gamePlayModule.question = null;
    });

    // ✅ Small delay to allow UI update before loading new content
    Future.delayed(const Duration(milliseconds: 100), () async {
      await gamePlayModule.roundInit(() {
        setState(() {
          _correctAnswer = gamePlayModule.question?['image_url'];
          gamePlayModule.imageOptions = [
            gamePlayModule.question?['image_url'],
            ...gamePlayModule.question?['distractor_images']
          ];
          gamePlayModule.imageOptions.shuffle(Random());
        });
      });

      // ✅ Start timer for the new round
      gamePlayModule.setTimer(() {
        _handleAnswer("", timeUp: true);
      });

      Logger().info("✅ New game round initialized!");
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

  void _closeFeedback() {
    _updateFeedbackState(showFeedback: false);
    _feedbackTimer?.cancel();

    setState(() {
      _selectedImageUrl = null; // ✅ Reset selected image
      fadedImages.clear(); // ✅ Clear faded images
    });

    _initializeGame(); // ✅ Reset game and change background
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

              GameImageGrid(
                imageOptions: gamePlayModule.imageOptions.map((e) => e.toString()).toList(),
                onImageTap: _handleAnswer,
                fadedImages: fadedImages,
                onAllImagesLoaded: _onImagesLoaded, // ✅ Call when images are loaded
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

              FactBox(
                facts: (gamePlayModule.question?['facts'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList(),
                onFactsLoaded: _onFactsLoaded, // ✅ Callback when facts are loaded
              ),
            ],
          ),
        ),

        // ✅ Full-Screen Feedback Overlay (Only when `_showFeedback` is true)
        if (_showFeedback)
          Positioned.fill(
            child: FeedbackMessage(
              feedback: _feedbackText,
              onClose: _closeFeedback,
              selectedImageUrl: _selectedImageUrl,
            ),
          ),

        // ✅ Use Consumer to track state changes in real-time
        Consumer<StateManager>(
          builder: (context, stateManager, child) {
            final gameRoundState = stateManager.getPluginState<Map<String, dynamic>>("game_round") ?? {};
            final isOverlayVisible = !(gameRoundState["imagesLoaded"] == true && gameRoundState["factLoaded"] == true);

            return isOverlayVisible
                ? Positioned(
              top: 100, // Adjust based on the height of the points bar
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.6), // ✅ Semi-transparent black overlay
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      "Loading...",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

}