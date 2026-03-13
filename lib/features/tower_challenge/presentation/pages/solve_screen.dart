import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/solve_game.dart';

// ═════════════════════════════════════════════════════════════════
//  FLUTTER PAGE WRAPPER
// ═════════════════════════════════════════════════════════════════
class SolvePage extends StatelessWidget {
  final int towerId;
  final int initialScore;
  final int remainingSeconds;

  const SolvePage({
    super.key,
    required this.towerId,
    this.initialScore = 125,
    this.remainingSeconds = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDD8),
      body: SafeArea(
        child: GameWidget(
          game: SolveGame(
            initialScore: initialScore,
            remainingSeconds: remainingSeconds,
            onBack: () => Get.back(),
            onSolved: (moves, time) => Get.back(
              result: {'solved': true, 'moves': moves, 'time': time},
            ),
          ),
        ),
      ),
    );
  }
}

