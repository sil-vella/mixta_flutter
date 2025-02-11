import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/00_base/module_base.dart';
import '../../../../tools/logging/logger.dart';

class AnimationsModule extends ModuleBase {
  static AnimationsModule? _instance;

  // List to store animation controllers for cleanup
  final List<AnimationController> _controllers = [];
  final Map<String, ConfettiController> _confettiControllers = {}; // ✅ Store confetti controllers

  AnimationsModule._internal() {
    Logger().info('AnimationsModule instance created.');
    _registerAnimationMethods();
  }

  /// Factory method to provide the singleton instance
  factory AnimationsModule() {
    if (_instance == null) {
      Logger().info('Initializing AnimationsModule for the first time.');
      _instance = AnimationsModule._internal();
    } else {
      Logger().info('AnimationsModule instance already exists.');
    }
    return _instance!;
  }

  void _registerAnimationMethods() {
    Logger().info('Registering animation methods in AnimationsModule.');
    registerMethod('applyFadeAnimation', applyFadeAnimation);
    registerMethod('applyScaleAnimation', applyScaleAnimation);
    registerMethod('applySlideAnimation', applySlideAnimation);
    registerMethod('applyBounceAnimation', applyBounceAnimation);
    registerMethod('playConfetti', (String key) => playConfetti(key: key)); // ✅ Correct function signature
    Logger().info('Animation methods registered successfully.');
  }

  /// Cleanup logic for AnimationsModule
  @override
  void dispose() {
    Logger().info('Cleaning up AnimationsModule resources.');

    // Dispose all animation controllers
    for (final controller in _controllers) {
      if (controller.isAnimating) {
        controller.stop(); // Stop any ongoing animations
      }
      controller.dispose(); // Dispose the controller
    }
    _controllers.clear();

    // Dispose all confetti controllers
    for (final confettiController in _confettiControllers.values) {
      confettiController.dispose();
    }
    _confettiControllers.clear();

    super.dispose();
  }

  /// Registers an AnimationController for later cleanup
  void registerController(AnimationController controller) {
    _controllers.add(controller);
    Logger().info('Registered AnimationController: $controller');
  }

  /// ✅ Method to trigger confetti animation
  void playConfetti({required String key}) {
    if (!_confettiControllers.containsKey(key)) {
      _confettiControllers[key] = ConfettiController(duration: const Duration(seconds: 2));
    }

    _confettiControllers[key]!.play();
    Logger().info('🎉 Confetti started: $key');
  }


  /// Applies fade animation to the provided widget
  Widget applyFadeAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    registerController(controller);
    Logger().info('Applying fade animation.');
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Opacity(
          opacity: controller.value,
          child: child,
        );
      },
    );
  }

  /// Applies scale animation to the provided widget
  Widget applyScaleAnimation({
    required Widget child,
    required AnimationController controller,
    double begin = 0.8,
    double end = 1.2,
  }) {
    registerController(controller);
    Logger().info('Applying scale animation.');
    final scaleAnimation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, _) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: child,
        );
      },
    );
  }

  /// Applies slide animation to the provided widget
  Widget applySlideAnimation({
    required Widget child,
    required AnimationController controller,
    Offset begin = const Offset(0, -1),
    Offset end = const Offset(0, 0),
  }) {
    registerController(controller);
    Logger().info('Applying slide animation.');
    final slideAnimation = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: slideAnimation,
      builder: (context, _) {
        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );
  }

  /// Applies bounce animation to the provided widget
  Widget applyBounceAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    registerController(controller);
    Logger().info('Applying bounce animation.');
    final bounceAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.bounceOut),
    );
    return AnimatedBuilder(
      animation: bounceAnimation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -bounceAnimation.value),
          child: child,
        );
      },
    );
  }
}
