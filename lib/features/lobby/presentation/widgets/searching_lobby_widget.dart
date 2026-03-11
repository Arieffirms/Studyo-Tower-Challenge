import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lobby_controller.dart';

class SearchingLobbyWidget extends GetView<LobbyController> {
  const SearchingLobbyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 30),
        const Text(
          'Searching for match...',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Player Count Stats
        Obx(() {
          final lobby = controller.activeLobby.value;
          final playerCount = lobby?.playerIds.length ?? 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Players matched: \$playerCount / 8',
              style: const TextStyle(fontSize: 18, color: Colors.blue),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Timer countdown
        Obx(() {
          final time = controller.secondsRemaining.value;
          final m = (time / 60).floor();
          final s = time % 60;
          return Text(
            "Time remaining: \${m.toString().padLeft(2, '0')}:\${s.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          );
        }),
        const SizedBox(height: 50),

        TextButton(
          onPressed: () {
            controller.isSearching.value = false;
            // Optionally could implement leave lobby usecase logic here
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: const Text(
            'Cancel Request',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
