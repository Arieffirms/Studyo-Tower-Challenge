import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flame/game.dart';
import '../controllers/arena_controller.dart';
import 'arena_game.dart';

class TowerChallengePage extends StatefulWidget {
  const TowerChallengePage({super.key});

  @override
  State<TowerChallengePage> createState() => _TowerChallengePageState();
}

class _TowerChallengePageState extends State<TowerChallengePage> {
  ArenaGame? _game;

  @override
  Widget build(BuildContext context) {
    // Ambil Argument (Lobby ID & UID) yang dikirim dari LobyController
    final args = Get.arguments;
    final String? lobbyId = args is Map ? args['lobbyId'] : args as String?;
    final String? uid = args is Map ? args['uid'] : null;

    if (_game == null) {
      _game = ArenaGame(
        lobbyId: lobbyId,
        uid: uid,
        onTeamSelected: (team) => _onTeamSelected(team, lobbyId, uid),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE2F4C5), // Light greenish-yellow from lobby
              Color(0xFFEEDAF1), // Light purple-pink
            ],
          ),
        ),
        child: Center(
          child: GameWidget(
            game: _game!,
          ),
        ),
      ),
    );
  }

  void _onTeamSelected(String team, String? lobbyId, String? uid) async {
    if (lobbyId != null && lobbyId != 'offline_match' && uid != null) {
      if (Get.isRegistered<ArenaController>()) {
        Get.find<ArenaController>().selectTeam(team);
      }
    }
  }
}
