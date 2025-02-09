import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:provider/provider.dart';
import '../../../core/00_base/screen_base.dart';
import '../../../core/managers/app_manager.dart';
import '../../../core/managers/module_manager.dart';
import '../../../core/managers/state_manager.dart';

class HomeScreen extends BaseScreen {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Home";
  }

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends BaseScreenState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Infinite bouncing effect
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget buildContent(BuildContext context) {
    final animationsModule = ModuleManager().getModule('animations_module');
    final stateManager = Provider.of<StateManager>(context, listen: false);

    // Update state and navigate when Play button is pressed
    void onPlayPressed() {
      stateManager.updateMainAppState('main_state', 'in_play');
      Navigator.pushNamed(context, '/game'); // ✅ Navigate to GameScreen
    }

    if (animationsModule == null) {
      return const Center(child: Text("Required modules are not available."));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          animationsModule.callMethod(
            'applyBounceAnimation',
            [],
            {
              'child': Text(
                'Welcome to the Mixta Game!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              'controller': _controller,
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onPlayPressed,
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

}
