import 'package:flutter/material.dart';
import 'package:mixta_guess_who/core/managers/module_manager.dart';
import '../../../../core/00_base/screen_base.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';

class LevelUpScreen extends BaseScreen {
  const LevelUpScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Well Done!";
  }

  @override
  LevelUpScreenState createState() => LevelUpScreenState();
}

class LevelUpScreenState extends BaseScreenState<LevelUpScreen> {
  final ServicesManager _servicesManager = ServicesManager();
  final ModuleManager _moduleManager = ModuleManager();

  bool _isLevelUp = false;
  bool _isEndGame = false;

  @override
  void initState() {
    super.initState();
    Logger().info("Initializing LevelUpScreen...");

    // ✅ Retrieve arguments to determine if it's a level-up or end-game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      setState(() {
        _isLevelUp = args?["levelUp"] ?? false;
        _isEndGame = args?["endGame"] ?? false;
      });

      Logger().info("🎯 LevelUp: $_isLevelUp | 🏆 EndGame: $_isEndGame");
    });
  }

  @override
  Widget buildContent(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isEndGame
                    ? [Colors.deepPurpleAccent, Colors.black87]
                    : [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isEndGame ? Icons.emoji_events : Icons.rocket_launch,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                _isEndGame
                    ? "🏆 Congratulations! You've completed the game!"
                    : "🎉 Level Up! You're now on the next stage!",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                _isEndGame
                    ? "You reached the highest level and proved your skills!"
                    : "Keep going! The next challenge awaits!",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/game");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _isEndGame ? Colors.deepPurple : Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  _isEndGame ? "Restart Game" : "Continue to Next Level",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
