import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/arena_player_model.dart';
import '../../data/repositories/tower_challenge_repository_impl.dart';
import '../../domain/usecases/claim_tower_usecase.dart';
import '../../domain/usecases/solve_tower_usecase.dart';
import '../../domain/usecases/release_tower_usecase.dart';
import '../../domain/usecases/observe_players_usecase.dart';

/// [ArenaController] manages all reactive game state for the Tower Challenge arena.
///
/// Responsibilities:
/// - Observing Firebase player stream and broadcasting updates
/// - Countdown timer management
/// - AFK detection and warning dialogs
/// - Bot simulation timer
/// - Tower claim / solve / release actions
/// - Match-finished score calculation
///
/// This controller is the single source of truth for the arena's state.
/// [ArenaBoardComponent] only renders based on what this controller emits.
class ArenaController extends GetxController {
  final TowerChallengeRepositoryImpl repository;
  final ClaimTowerUseCase claimTowerUseCase;
  final SolveTowerUseCase solveTowerUseCase;
  final ReleaseTowerUseCase releaseTowerUseCase;
  final ObservePlayersUseCase observePlayersUseCase;

  ArenaController({
    required this.repository,
    required this.claimTowerUseCase,
    required this.solveTowerUseCase,
    required this.releaseTowerUseCase,
    required this.observePlayersUseCase,
  });

  // ─────────────────── Match Identity ────────────────────────────────────────
  String? matchId;
  String? uid;

  // ─────────────────── Reactive State ────────────────────────────────────────
  /// All players keyed by playerId. Updated live from Firebase.
  final players = <String, ArenaPlayerModel>{}.obs;

  final selectedTeam = Rx<String?>(null);
  final myTowerId = Rx<int?>(null);
  final remainingSeconds = 300.obs;
  final isGameStarted = false.obs;
  final isTopFinished = false.obs;
  final isBottomFinished = false.obs;

  // Solved tower tracking (non-reactive — used only by ArenaBoardComponent via getter)
  final solvedTopTowers = <int>{};
  final solvedBottomTowers = <int>{};
  final solvedBotTopTowers = <int>{};
  final solvedBotBottomTowers = <int>{};

  // ─────────────────── Internal timers ───────────────────────────────────────
  Timer? _countdownTimer;
  Timer? _heartbeatTimer;
  StreamSubscription<Map<String, ArenaPlayerModel>>? _playersSub;

  final _random = Random();

  // ─────────────────── Lifecycle ─────────────────────────────────────────────

  /// Call this from [ArenaBoardComponent.onMount] to start all listeners.
  void start(String matchId, String uid) {
    this.matchId = matchId;
    this.uid = uid;
    _listenToPlayers();
    _listenToMeta();
    _sendHeartbeatPeriodic();
  }

  @override
  void onClose() {
    _playersSub?.cancel();
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.onClose();
  }

  // ─────────────────── Firebase Listeners ────────────────────────────────────

  void _listenToPlayers() {
    if (matchId == null) return;
    _playersSub?.cancel();
    _playersSub = observePlayersUseCase(matchId!).listen((snapshot) {
      players.assignAll(snapshot);
    });
  }

  Future<void> _listenToMeta() async {
    if (matchId == null) return;
    final meta = await repository.fetchMatchMeta(matchId!);
    if (meta == null) return;

    final int? startAt = meta['startAt'] as int?;
    final int durationSec = meta['durationSec'] ?? 300;

    if (startAt != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = ((now - startAt) / 1000).floor();
      final remaining = durationSec - elapsed;
      remainingSeconds.value = remaining.clamp(0, durationSec);
    } else {
      remainingSeconds.value = durationSec;
    }

    _startCountdown();
  }

  // ─────────────────── Timer ─────────────────────────────────────────────────

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds.value <= 0) {
        t.cancel();
        if (!isTopFinished.value && !isBottomFinished.value) {
          isTopFinished.value = true;
          isBottomFinished.value = true;
        }
      } else {
        remainingSeconds.value--;
      }
    });
  }

  // ─────────────────── Heartbeat ──────────────────────────────────────────────

  void _sendHeartbeatPeriodic() {
    if (uid == null) return;
    _sendHeartbeat();
    _heartbeatTimer?.cancel();
    // Send heartbeat every 10s to keep lastSeenAt fresh
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _sendHeartbeat(),
    );
  }

  void _sendHeartbeat() {
    if (matchId == null || uid == null) return;
    repository.updateHeartbeat(matchId!, uid!);
  }

  /// No-op — board-level AFK removed. AFK only in SolveScreen.
  void resetAfkTimer() {}

  // ─────────────────── Tower Actions ─────────────────────────────────────────

  /// Claims a tower for the current human player.
  Future<bool> claimTower(int towerId) async {
    if (matchId == null || uid == null || selectedTeam.value == null)
      return false;
    myTowerId.value = towerId;
    return await claimTowerUseCase(
      matchId: matchId!,
      teamId: selectedTeam.value!,
      towerId: towerId.toString(),
      playerId: uid!,
    );
  }

  /// Submits a solved result for a tower.
  Future<void> solveTower(int towerId, int movesTaken) async {
    if (matchId == null || uid == null || selectedTeam.value == null) return;
    await repository.solveTower(
      matchId: matchId!,
      teamId: selectedTeam.value!,
      towerId: towerId.toString(),
      playerId: uid!,
      movesTaken: movesTaken,
      optimalMoves: 0, // optimal move tracking is a future enhancement
    );
    myTowerId.value = null;
    final isTop = selectedTeam.value == 'A';
    (isTop ? solvedTopTowers : solvedBottomTowers).add(towerId);
  }

  /// Releases a tower the player backed out of without solving.
  Future<void> releaseTower(int towerId) async {
    if (matchId == null || selectedTeam.value == null) return;
    await releaseTowerUseCase(
      matchId: matchId!,
      teamId: selectedTeam.value!,
      towerId: towerId.toString(),
    );
    myTowerId.value = null;
  }

  /// Assigns a team to the current player and balances bots
  Future<void> selectTeam(String team) async {
    if (matchId == null || matchId == 'offline_match' || uid == null) return;
    await repository.assignTeamAndBalanceBots(matchId!, uid!, team);
  }

  // ─────────────────── Bot Simulation ────────────────────────────────────────

  /// Called by ArenaBoardComponent when a bot finishes its visual solving animation.
  /// Exactly matches the bot's visual progress to its Firebase score/stats update!
  Future<void> onBotSolvedTower(String botId) async {
    if (matchId == null) return;

    final bot = players[botId];
    if (bot == null || !bot.isBot || bot.team == null) return;

    final movesToAdd = _random.nextInt(4) + 2; // 2 to 5 moves simulated
    await repository.simulateBotMove(
      matchId: matchId!,
      botId: botId,
      movesToAdd: movesToAdd,
    );
  }

  // ─────────────────── Match Completion ──────────────────────────────────────

  Future<void> calculateFinalScore() async {
    if (matchId == null) return;

    int scoreA = 0;
    int scoreB = 0;

    for (final p in players.values) {
      if (p.team == 'A') {
        scoreA += p.score;
      } else if (p.team == 'B') {
        scoreB += p.score;
      }
    }

    // Update Firebase with final team scores before showing the dialog
    await repository.updateTeamScores(matchId!, scoreA, scoreB);

    // Stop heartbeat once the game is finished and scores are pushed
    _heartbeatTimer?.cancel();

    String title;
    Color titleColor;
    if (scoreA > scoreB) {
      title = 'TEAM A WINS!';
      titleColor = Colors.orange;
    } else if (scoreB > scoreA) {
      title = 'TEAM B WINS!';
      titleColor = Colors.blueAccent;
    } else {
      title = "IT'S A TIE!";
      titleColor = Colors.purple;
    }

    Future.delayed(const Duration(seconds: 2), () {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MATCH FINISHED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Team A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          '$scoreA',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Team B',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        Text(
                          '$scoreB',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DE0B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () => Get.offAllNamed('/lobby'),
                  child: const Text(
                    'Back to Lobby',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    });
  }
}
