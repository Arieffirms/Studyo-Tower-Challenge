import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lobby_controller.dart';

class MainMenuWidget extends GetView<LobbyController> {
  const MainMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Tower Challenge',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Team Mini-Game',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 50),
        ElevatedButton(
          onPressed: () => controller.joinOnlineMatchmaking(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: const Text('Play Online'),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => controller.playVsComputer(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: const Text('Play vs Computer'),
        ),
      ],
    );
  }
}
