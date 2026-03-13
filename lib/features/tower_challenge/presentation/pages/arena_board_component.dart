import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame_lottie/flame_lottie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async' as async_io;

import '../controllers/arena_controller.dart';
import '../../data/models/arena_player_model.dart';
import 'mock_tower_component.dart';
import 'solve_screen.dart';



class ArenaBoardComponent extends PositionComponent
    with HasGameRef, DragCallbacks {
  final String? lobbyId;
  final String? uid;
  final ValueChanged<String>? onTeamSelected;
  bool hasStarted = false;
  String? _selectedTeam;
  int? _myTowerId;
  final Set<int> _solvedTopTowers = {};
  final Set<int> _solvedBottomTowers = {};
  final Set<int> _solvedBotTopTowers = {};
  final Set<int> _solvedBotBottomTowers = {};
  // Countdown is managed by ArenaController.

  async_io.StreamSubscription<void>? _controllerSub;

  // BFS car position: which tower index each team's car is currently at
  int _topCarIdx = 0;
  int _botCarIdx = 0;
  async_io.Timer? _bfsCarTimer;

  // ─── Delegated to ArenaController ───────────────────────────────────────
  /// Proxy getter: returns the reactive player map from ArenaController.
  Map<String, ArenaPlayerModel> get _latestPlayers =>
      Get.find<ArenaController>().players;

  /// Proxy getter: tracks active bot names via controller's internal tracking.
  /// Since bots are simulated inside ArenaController, we keep a local set here
  /// only for Flame rendering purposes (which bot avatar is currently in a tower).
  final Set<String> _activeBotNames = <String>{};

  bool isTopFinished = false;
  bool isBottomFinished = false;
  LottieComponent? _topSuccessLottie;
  LottieComponent? _bottomSuccessLottie;

  ArenaBoardComponent({this.lobbyId, this.uid, this.onTeamSelected});
  // Use a softer green from the image
  final Paint _bgPaint = Paint()..color = const Color(0xFF6DE0B2);
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFF3B9B70)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  // Divider
  final Paint _dividerPaint = Paint()
    ..color = const Color(0xFF3B9B70)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  late PositionComponent _topTowersContainer;
  late PositionComponent _bottomTowersContainer;
  double _minScroll = 0;

  @override
  Future<void> onLoad() async {
    _topTowersContainer = PositionComponent();
    _bottomTowersContainer = PositionComponent();
    add(_topTowersContainer);
    add(_bottomTowersContainer);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Board padding
    final px = 15.0;
    final py = 60.0;

    this.size = Vector2(size.x - px * 2, size.y - py * 2);
    this.position = Vector2(px, py);

    _topTowersContainer.removeAll(_topTowersContainer.children);
    _bottomTowersContainer.removeAll(_bottomTowersContainer.children);

    // We want 20 total active towers as per README.
    // Let's display around 5.0 columns visibly on the screen at a time.
    final visibleColumns = 5.0; // Scaled down the towers globally
    final segW = this.size.x / visibleColumns;
    final totalColumns = 20;
    final totalWidth = totalColumns * segW;
    _topTowersContainer.size = Vector2(totalWidth, this.size.y);
    _bottomTowersContainer.size = Vector2(totalWidth, this.size.y);

    _minScroll = -(totalWidth - this.size.x);
    if (_minScroll > 0) _minScroll = 0;

    _buildHalf(isTop: true, segW: segW, totalColumns: totalColumns);
    _buildHalf(isTop: false, segW: segW, totalColumns: totalColumns);
  }

  @override
  void onMount() {
    super.onMount();
    if (lobbyId != null && lobbyId != 'offline_match' && uid != null) {
      // Delegate all Firebase listeners, timers, and bot simulation to ArenaController.
      final ctrl = Get.find<ArenaController>();
      ctrl.start(lobbyId!, uid!);

      // Reactively sync players from controller to trigger avatar updates.
      _controllerSub = ctrl.players.listen((_) {
        if (hasStarted) _updateRealtimeAvatars();
      }) as async_io.StreamSubscription<void>?;

      // When the countdown reaches 0, disable all plus buttons on the board.
      ever(ctrl.remainingSeconds, (secs) {
        if (secs <= 0) disableAllPlus();
      });
    }
  }

  @override
  void onRemove() {
    _controllerSub?.cancel();
    _bfsCarTimer?.cancel();
    super.onRemove();
  }

  // ─── All AFK, heartbeat, bot sim, countdown, and Firebase listener logic ───
  // ─── has been moved to ArenaController. ─────────────────────────────────────

  // Stubs removed — logic lives in ArenaController.

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Notify controller that user is active (resets AFK timer)
    try { Get.find<ArenaController>().resetAfkTimer(); } catch (_) {}
    if (event.localEndPosition.y < size.y / 2) {
      // Top team dragged
      _topTowersContainer.position.x += event.localDelta.x;
      if (_topTowersContainer.position.x > 0) {
        _topTowersContainer.position.x = 0;
      } else if (_topTowersContainer.position.x < _minScroll) {
        _topTowersContainer.position.x = _minScroll;
      }
    } else {
      // Bottom team dragged
      _bottomTowersContainer.position.x += event.localDelta.x;
      if (_bottomTowersContainer.position.x > 0) {
        _bottomTowersContainer.position.x = 0;
      } else if (_bottomTowersContainer.position.x < _minScroll) {
        _bottomTowersContainer.position.x = _minScroll;
      }
    }
  }

  void activateGame(String selectedTeam) {
    _selectedTeam = selectedTeam;
    // Realtime UI mapping instead of full layout reset
    _updateRealtimeAvatars();
    // Immediately lock towers 1-4 for bots (no visible + during delay)
    if (_myTowerId != null) {
      _assignInitialBotTowers(selectedTeam, _myTowerId!);
    }
    // Dynamic bot simulation (names from Firebase) + BFS car movement
    _runDynamicBotSimulation();
    _startBFSCarProgress();
  }

  /// Immediately claims towers 1–4 (except [playerTowerId]) for bots.
  /// Removes '+', sets state=working, shows typing. Also starts each bot's
  /// solve loop so the tower eventually resolves and the bot moves on.
  void _assignInitialBotTowers(String team, int playerTowerId) {
    final isTop = team == 'A';
    final container = isTop ? _topTowersContainer : _bottomTowersContainer;
    final towers = container.children.whereType<MockTowerComponent>().toList();
    final botSolvedSet = isTop ? _solvedBotTopTowers : _solvedBotBottomTowers;
    final userSolvedSet = isTop ? _solvedTopTowers : _solvedBottomTowers;

    // Get available bots for this team (exactly 3 bots, stable order)
    final bots = _latestPlayers.values
        .where((p) => p.isBot && p.team == team)
        .take(3)
        .toList();

    // Find all valid idle towers (excluding the player's chosen tower)
    final available = <int>[];
    for (int i = 1; i < towers.length; i++) {
      if (i != playerTowerId && towers[i].towerState == TowerState.idle) {
        available.add(i);
      }
    }

    // Assign exactly 1 random tower per available bot
    for (int botIdx = 0; botIdx < bots.length; botIdx++) {
      if (available.isEmpty) break; // No more towers left

      final bot = bots[botIdx];
      // Randomly pick a tower from the available pool and remove it so it's not picked twice
      final randIndex = Random().nextInt(available.length);
      final idx = available.removeAt(randIndex);

      // ── Claim visually RIGHT NOW ──────────────────────────────────────────
      towers[idx].towerState = TowerState.working;
      towers[idx].removePlus(); // Remove '+' immediately
      towers[idx].updateAvatar(bot.name, particles: true);

      // Register in active set so _runDynamicBotSimulation's staggered
      // _botSolveLoop call is blocked for this bot (no duplicate loop)
      _activeBotNames.add(bot.name);

      // ── Start solve loop for this initial tower ───────────────────────────
      final capturedIdx = idx;
      final solveSeconds = 25 + Random().nextInt(11); // 25-35s
      Future.delayed(Duration(seconds: solveSeconds), () {
        // Safety: if user solved this tower in the meantime, just move on
        if (userSolvedSet.contains(capturedIdx)) {
          towers[capturedIdx].towerState = TowerState.idle;
          _activeBotNames.remove(bot.name); // Release
          _botSolveLoop(bot, towers, botSolvedSet);
          return;
        }

        // Transition working → solved
        towers[capturedIdx].towerState = TowerState.solved;
        botSolvedSet.add(capturedIdx);
        
        // Let the controller know the bot successfully solved a tower so it can update Firebase stats
        Get.find<ArenaController>().onBotSolvedTower(bot.id);

        if (size.y > 0) {
          final maxH = (size.y / 2) * 0.50;
          final fillH = (maxH - towers[capturedIdx].size.y).clamp(0.0, maxH);
          towers[capturedIdx].setBlueProgress(fillH);
        }

        Future.delayed(const Duration(milliseconds: 900), () {
          towers[capturedIdx].clearContent();
          // Release before recursion so _botSolveLoop guard re-enters cleanly
          _activeBotNames.remove(bot.name);
          _botSolveLoop(bot, towers, botSolvedSet);
        });
      });
    }
  }

  void _updateRealtimeAvatars() {
    final topTowers = _topTowersContainer.children
        .whereType<MockTowerComponent>()
        .toList();
    final botTowers = _bottomTowersContainer.children
        .whereType<MockTowerComponent>()
        .toList();

    final teamAPlayers = _latestPlayers.values
        .where((p) => p.team == 'A')
        .toList();
    final teamBPlayers = _latestPlayers.values
        .where((p) => p.team == 'B')
        .toList();

    ArenaPlayerModel? myPlayerA;
    final selectedBotsA = <ArenaPlayerModel>[];
    // Pass 1: Add currently working bots to lock their slot
    for (final p in teamAPlayers) {
      if (p.id == uid)
        myPlayerA = p;
      else if (p.isBot && _activeBotNames.contains(p.name))
        selectedBotsA.add(p);
    }
    // Pass 2: Fill remaining slots up to 3 with idle bots
    for (final p in teamAPlayers) {
      if (p.isBot &&
          !_activeBotNames.contains(p.name) &&
          selectedBotsA.length < 3) {
        selectedBotsA.add(p);
      }
    }
    // Only idle bots are placed on idle towers
    final otherPlayersA = selectedBotsA
        .where((p) => !_activeBotNames.contains(p.name))
        .toList();
    if (_myTowerId == null && !hasStarted && myPlayerA != null) {
      otherPlayersA.insert(0, myPlayerA);
    }

    ArenaPlayerModel? myPlayerB;
    final selectedBotsB = <ArenaPlayerModel>[];
    // Pass 1: Add currently working bots to lock their slot
    for (final p in teamBPlayers) {
      if (p.id == uid)
        myPlayerB = p;
      else if (p.isBot && _activeBotNames.contains(p.name))
        selectedBotsB.add(p);
    }
    // Pass 2: Fill remaining slots up to 3 with idle bots
    for (final p in teamBPlayers) {
      if (p.isBot &&
          !_activeBotNames.contains(p.name) &&
          selectedBotsB.length < 3) {
        selectedBotsB.add(p);
      }
    }
    // Only idle bots are placed on idle towers
    final otherPlayersB = selectedBotsB
        .where((p) => !_activeBotNames.contains(p.name))
        .toList();
    if (_myTowerId == null && !hasStarted && myPlayerB != null) {
      otherPlayersB.insert(0, myPlayerB);
    }

    if (topTowers.length > 4) {
      topTowers[0].updateAvatar('', newHasCar: true, newLabel: '1000');

      for (int i = 1; i < topTowers.length; i++) {
        // ─ GUARD: solved towers must stay clear — no avatar, no typing ─
        final isBotSolvedTop = _solvedBotTopTowers.contains(i);
        final isUserSolvedTop = _solvedTopTowers.contains(i);
        if (isBotSolvedTop || isUserSolvedTop) {
          // Actively clear stale avatar/typing that DB may have set
          if (topTowers[i].avatarName.isNotEmpty) {
            topTowers[i].avatarName = '';
            topTowers[i].stopParticles();
          }
          if (hasStarted) topTowers[i].removePlus();
          continue; // Do not consume from otherPlayersA: idle bots flow to next idle tower
        }

        // ─ GUARD: bot-working towers — skip Firebase reassignment ─
        if (topTowers[i].towerState == TowerState.working && i != _myTowerId) {
          continue; // Do not consume from otherPlayersA: the working bot is completely removed from the idle pool
        }

        ArenaPlayerModel? p;
        if (i == _myTowerId && _selectedTeam == 'A' && myPlayerA != null) {
          p = myPlayerA;
        } else if (otherPlayersA.isNotEmpty) {
          p = otherPlayersA.removeAt(0);
        }

        if (p != null) {
          final isMine = p.id == uid;
          // Pre-game: all keep +. Post-game: user's unsolved tower OR bot's unsolved tower
          bool keepP =
              !hasStarted ||
              ((_selectedTeam == 'A') &&
                  isMine &&
                  !_solvedTopTowers.contains(i)) ||
              (p.isBot && !_solvedBotTopTowers.contains(i));

          topTowers[i].updateAvatar(
            p.name,
            keepPlus: keepP,
            particles:
                false, // typing.json only set by _botSolveLoop when actually working
            isAFK: Get.find<ArenaController>().isTopFinished.value ? false : p.isAFK,
          );
          if (hasStarted) {
            _animateTowerHeight(topTowers[i], _solvedTopTowers.contains(i));
            if (!keepP) topTowers[i].removePlus();
          }
        } else {
          topTowers[i].updateAvatar('');
          // Only remove + if this slot is actually solved — keep it for user to freely pick
          if (hasStarted &&
              (_solvedTopTowers.contains(i) ||
                  _solvedBotTopTowers.contains(i))) {
            topTowers[i].removePlus();
          }
        }
      }
      if (_selectedTeam == 'B') for (final t in topTowers) t.removePlus();
    }

    if (botTowers.length > 4) {
      botTowers[0].updateAvatar('', newHasCar: true, newLabel: '1000');

      for (int i = 1; i < botTowers.length; i++) {
        // ─ GUARD: solved bot towers must stay clear ─
        final isBotSolvedBot = _solvedBotBottomTowers.contains(i);
        final isUserSolvedBot = _solvedBottomTowers.contains(i);
        if (isBotSolvedBot || isUserSolvedBot) {
          if (botTowers[i].avatarName.isNotEmpty) {
            botTowers[i].avatarName = '';
            botTowers[i].stopParticles();
          }
          if (hasStarted) botTowers[i].removePlus();
          continue; // Do not consume slot: flow idle bots right
        }

        // ─ GUARD: bot-working towers — skip Firebase reassignment ─
        if (botTowers[i].towerState == TowerState.working && i != _myTowerId) {
          continue; // Do not consume slot: working bot is cleanly isolated
        }

        ArenaPlayerModel? p;
        if (i == _myTowerId && _selectedTeam == 'B' && myPlayerB != null) {
          p = myPlayerB;
        } else if (otherPlayersB.isNotEmpty) {
          p = otherPlayersB.removeAt(0);
        }

        if (p != null) {
          final isMine = p.id == uid;
          bool keepP =
              !hasStarted ||
              ((_selectedTeam == 'B') &&
                  isMine &&
                  !_solvedBottomTowers.contains(i)) ||
              (p.isBot && !_solvedBotBottomTowers.contains(i));

          botTowers[i].updateAvatar(
            p.name,
            keepPlus: keepP,
            particles: false,
            isAFK: Get.find<ArenaController>().isBottomFinished.value ? false : p.isAFK,
          );
          if (hasStarted) {
            _animateTowerHeight(botTowers[i], _solvedBottomTowers.contains(i));
            if (!keepP) botTowers[i].removePlus();
          }
        } else {
          botTowers[i].updateAvatar('');
          // Only remove + if this slot is solved — keep it for user to freely pick
          if (hasStarted &&
              (_solvedBottomTowers.contains(i) ||
                  _solvedBotBottomTowers.contains(i))) {
            botTowers[i].removePlus();
          }
        }
      }
      if (_selectedTeam == 'A') for (final t in botTowers) t.removePlus();
    }
  }

  void _animateTowerHeight(MockTowerComponent tower, bool isSolved) {
    if (size.y == 0) return;
    final maxTowerH = (size.y / 2) * 0.50;
    // Blue fills the REMAINING space above the purple base so total = 1000-tower height
    final remainingH = (maxTowerH - tower.size.y).clamp(0.0, maxTowerH);
    final targetH = isSolved ? remainingH : 0.0;
    tower.setBlueProgress(targetH);
  }

  // ── BFS Car Progress: car advances tower-by-tower in order ───────────────
  void _startBFSCarProgress() {
    _bfsCarTimer = async_io.Timer.periodic(const Duration(milliseconds: 1500), (
      _,
    ) {
      if (!hasStarted) return;
      _advanceCarBFS(isTop: true);
      _advanceCarBFS(isTop: false);
    });
  }

  void _advanceCarBFS({required bool isTop}) {
    final container = isTop ? _topTowersContainer : _bottomTowersContainer;
    final towers = container.children.whereType<MockTowerComponent>().toList();
    if (towers.isEmpty) return;

    // Union of user-solved and bot-solved sets for this half
    final allSolved = isTop
        ? {..._solvedTopTowers, ..._solvedBotTopTowers}
        : {..._solvedBottomTowers, ..._solvedBotBottomTowers};

    final curIdx = isTop ? _topCarIdx : _botCarIdx;
    final nextIdx = curIdx + 1;

    // Only advance if the very next sequential tower is solved (BFS rule)
    if (nextIdx < towers.length && allSolved.contains(nextIdx)) {
      final car = towers[0].children.whereType<LottieComponent>().firstOrNull;
      if (car != null) {
        // Delta from CURRENT car position to NEXT tower
        final dx = towers[nextIdx].position.x - towers[curIdx].position.x;
        car.add(
          MoveEffect.by(
            Vector2(dx, 0),
            EffectController(duration: 1.2, curve: Curves.easeInOutCubic),
            onComplete: () {
              // Car has just finished moving to nextIdx
              if (nextIdx >= 19) {
                if (isTop && !isTopFinished) {
                  isTopFinished = true;
                  _showSuccessLottie(isTop: true);
                } else if (!isTop && !isBottomFinished) {
                  isBottomFinished = true;
                  _showSuccessLottie(isTop: false);
                }

                if (isTopFinished && isBottomFinished) {
                  Get.find<ArenaController>().calculateFinalScore();
                }
              }
            },
          ),
        );
      }
      if (isTop)
        _topCarIdx = nextIdx;
      else
        _botCarIdx = nextIdx;
    }
  }

  void _runDynamicBotSimulation() {
    // Wait 2s for Firebase data and towers to be ready
    Future.delayed(const Duration(seconds: 2), () {
      final topTowers = _topTowersContainer.children
          .whereType<MockTowerComponent>()
          .toList();
      final botTowers = _bottomTowersContainer.children
          .whereType<MockTowerComponent>()
          .toList();

      final teamABots = _latestPlayers.values
          .where((p) => p.isBot && p.team == 'A')
          .take(3)
          .toList();
      final teamBBots = _latestPlayers.values
          .where((p) => p.isBot && p.team == 'B')
          .take(3)
          .toList();

      // Stagger start so bots don’t collide on the same tower
      for (int i = 0; i < teamABots.length; i++) {
        final delay = i * 3;
        Future.delayed(Duration(seconds: delay), () {
          _botSolveLoop(teamABots[i], topTowers, _solvedBotTopTowers);
        });
      }
      for (int i = 0; i < teamBBots.length; i++) {
        final delay = i * 3;
        Future.delayed(Duration(seconds: delay), () {
          _botSolveLoop(teamBBots[i], botTowers, _solvedBotBottomTowers);
        });
      }
    });
  }

  void _botSolveLoop(
    ArenaPlayerModel bot,
    List<MockTowerComponent> towers,
    Set<int> botSolvedSet, // bot-solved set for this team
  ) {
    // Determine which user-solved set to cross-check (same object reference)
    final userSolvedSet = identical(botSolvedSet, _solvedBotTopTowers)
        ? _solvedTopTowers
        : _solvedBottomTowers;

    // ── Build list of valid candidate towers ─────────────────────────────────
    // A tower is valid if state == idle (not working, not solved)
    final available = <int>[];
    for (int i = 1; i < towers.length; i++) {
      if (towers[i].towerState == TowerState.idle) {
        available.add(i);
      }
    }

    if (available.isEmpty) return; // All towers solved or all occupied — stop

    // ── Deduplication guard ──────────────────────────────────────────────────
    // A bot may only have ONE active solve loop at a time. If _assignInitialBotTowers
    // already started this bot, _runDynamicBotSimulation's call returns here.
    if (_activeBotNames.contains(bot.name)) return;

    // ── Max 4 Worker Limit ───────────────────────────────────────────────────
    final workingCount = towers
        .where((t) => t.towerState == TowerState.working)
        .length;
    if (workingCount >= 4) {
      // Too many workers active. Delay and try again later.
      Future.delayed(const Duration(seconds: 3), () {
        _botSolveLoop(bot, towers, botSolvedSet);
      });
      return;
    }

    _activeBotNames.add(bot.name);

    // Random selection from validated available towers (no retry loop needed)
    final idx = available[Random().nextInt(available.length)];

    // Claim tower: transition idle → working
    towers[idx].towerState = TowerState.working;
    // Immediately remove + so it's visually locked for players and other bots
    towers[idx].removePlus();
    // Show bot on chosen tower — typing animation = actively solving
    towers[idx].updateAvatar(bot.name, particles: true);

    // Fixed solve time: 25-35 seconds for realistic and stable gameplay
    final solveSeconds = 25 + Random().nextInt(11);
    Future.delayed(Duration(seconds: solveSeconds), () {
      // Double-check tower wasn't claimed/solved by user while bot was working
      if (userSolvedSet.contains(idx)) {
        towers[idx].towerState = TowerState.idle; // restore for others
        _botSolveLoop(bot, towers, botSolvedSet);
        return;
      }

      // Transition working → solved
      towers[idx].towerState = TowerState.solved;
      botSolvedSet.add(idx);
      
      // Hit the controller to update Firebase stats EXACTLY when the tower turns blue!
      Get.find<ArenaController>().onBotSolvedTower(bot.id);

      // Grow blue tower to exactly the 1000 reference height
      if (size.y > 0) {
        final maxTowerH = (size.y / 2) * 0.50;
        final fillH = (maxTowerH - towers[idx].size.y).clamp(0.0, maxTowerH);
        towers[idx].setBlueProgress(fillH);
      }

      // Brief pause → clear avatar → immediately hunt next valid tower
      Future.delayed(const Duration(milliseconds: 900), () {
        towers[idx].clearContent();
        _activeBotNames.remove(bot.name); // Release before recursing
        _botSolveLoop(bot, towers, botSolvedSet); // Recurse (re-enters guard)
      });
    });
  }

  Future<void> _openSolveScreen(
    int towerId,
    int initialScore,
    bool isTopScreen,
  ) async {
    final container = isTopScreen
        ? _topTowersContainer
        : _bottomTowersContainer;
    final towers = container.children.whereType<MockTowerComponent>().toList();

    // Show typing and mark tower as WORKING while user is on solve screen
    if (towers.length > towerId) {
      towers[towerId].towerState = TowerState.working;
      towers[towerId].updateAvatar(
        towers[towerId].avatarName,
        particles: true,
        keepPlus: true,
      );
    }

    final result = await Get.to(
      () => SolvePage(
        towerId: towerId,
        initialScore: initialScore,
        remainingSeconds: (() {
          try { return Get.find<ArenaController>().remainingSeconds.value; }
          catch (_) { return 300; }
        })(),
      ),
      transition: Transition.downToUp,
    );

    // Remove typing animation regardless of result
    if (towers.length > towerId) {
      towers[towerId].stopParticles();
    }

    if (result != null && result is Map && result['solved'] == true) {
      final int moves = result['moves'] ?? 0;

      // Mark tower as solved (prevents + from reappearing on DB refresh)
      if (isTopScreen) {
        _solvedTopTowers.add(towerId);
      } else {
        _solvedBottomTowers.add(towerId);
      }

      // Transition working → solved
      if (towers.length > towerId) {
        towers[towerId].towerState = TowerState.solved;
      }

      // Jump the tower to FULL 1000 height
      if (towers.length > towerId) {
        final maxTowerH = (size.y / 2) * 0.50;
        final purpleH = towers[towerId].size.y;
        final fillH = (maxTowerH - purpleH).clamp(0.0, maxTowerH);
        towers[towerId].setBlueProgress(fillH);
      }

      // Clear avatar & free user to pick another tower
      if (towers.length > towerId) {
        towers[towerId].updateAvatar('');
      }
      _myTowerId = null;

      // BFS car movement handles advancing the car sequentially—
      // _advanceCarBFS() will move it to this tower once prior towers are solved.

      // Update Firebase stats via ArenaController (Clean Architecture)
      if (uid != null && lobbyId != null) {
        try {
          final ctrl = Get.find<ArenaController>();
          final team = ctrl.selectedTeam.value ?? (isTopScreen ? 'A' : 'B');
          await ctrl.repository.solveTower(
            matchId: lobbyId!,
            teamId: team,
            towerId: towerId.toString(),
            playerId: uid!,
            movesTaken: moves,
            optimalMoves: 0,
          );
        } catch (e) {
          debugPrint('solveTower via controller failed: $e');
        }
      }

      // Remove + from the solved tower visually
      if (towers.length > towerId) towers[towerId].removePlus();
    } else {
      // Back / Cancel — clear avatar and restore tower to IDLE
      if (towers.length > towerId) {
        towers[towerId].updateAvatar(''); // Remove avatar immediately
        towers[towerId].towerState = TowerState.idle;
      }
      _myTowerId = null; // Tower is free — user can pick any idle tower next
    }
  }

  // Meta, countdown, and formatting helpers delegated to ArenaController.

  void disableAllPlus() {
    for (final t
        in _topTowersContainer.children.whereType<MockTowerComponent>()) {
      t.removePlus();
    }
    for (final t
        in _bottomTowersContainer.children.whereType<MockTowerComponent>()) {
      t.removePlus();
    }
  }

  void _buildHalf({
    required bool isTop,
    required double segW,
    required int totalColumns,
  }) {
    final parentContainer = isTop
        ? _topTowersContainer
        : _bottomTowersContainer;
    final halfHeight = size.y / 2;
    final startY = isTop ? 0.0 : halfHeight;

    const baseColor = Color(0xFF7D59A4); // Purple
    final floorHeight = 40.0;
    final floorY = startY + halfHeight - floorHeight;

    // Add continuous floor
    parentContainer.add(
      RectangleComponent(
        size: Vector2(totalColumns * segW, floorHeight),
        position: Vector2(0, floorY),
        paint: Paint()..color = baseColor,
      ),
    );

    // Tower 0 = always 1000 (goal tower).
    // Towers 1-N: random multiples of 10 in range 150-900.
    // Multiples of 10 are always solvable with +10 and ×2 moves.
    final _rng = Random();
    final initialPattern = List.generate(
      totalColumns,
      (i) => i == 0 ? 1000 : (15 + _rng.nextInt(76)) * 10, // 150,160..900
    );
    final maxTowerH = halfHeight * 0.50;

    for (int i = 0; i < totalColumns; i++) {
      final int myInitialScore = i < initialPattern.length
          ? initialPattern[i]
          : 10;
      final double scoreRatio = (myInitialScore / 1000.0).clamp(0.01, 1.0);
      final towerH = maxTowerH * scoreRatio;

      final tower =
          MockTowerComponent(
              id: i, // Give the tower its ID!
              color: baseColor,
              label: '', // Initially empty, filled by activateGame if needed
              hasCar: i == 0, // <--- Load the car on the 1000 tower!
              isPlus: i >= 1,
              onPlusTapped: () {
                if (isTop ? isTopFinished : isBottomFinished)
                  return; // Block interactions if team is done

                debugPrint(
                  'Plus tapped on tower ID: $i, team: ${isTop ? "Top" : "Bottom"}',
                );

                // Reset AFK timer on valid interaction
                try { Get.find<ArenaController>().resetAfkTimer(); } catch (_) {}

                // === STATE GUARD: only idle towers are clickable ===
                final container = isTop
                    ? _topTowersContainer
                    : _bottomTowersContainer;
                final allTowers = container.children
                    .whereType<MockTowerComponent>()
                    .toList();
                if (i < allTowers.length &&
                    allTowers[i].towerState != TowerState.idle) {
                  return; // Tower is working or solved — block tap
                }

                // === MAX WORKER GUARD ===
                final workingCount = allTowers
                    .where((t) => t.towerState == TowerState.working)
                    .length;
                if (workingCount >= 4) {
                  debugPrint('Team already has 4 active workers. Tap blocked.');
                  return; // Block tap if team already has 4 workers
                }

                // Guard: block wrong team after game starts
                final teamStr = isTop ? 'A' : 'B';
                if (hasStarted &&
                    _selectedTeam != null &&
                    _selectedTeam != teamStr)
                  return;

                _myTowerId = i;
                if (!hasStarted) {
                  hasStarted = true;
                  onTeamSelected?.call(teamStr);
                  activateGame(teamStr);
                }
                if (i >= 1) {
                  _openSolveScreen(i, myInitialScore, isTop);
                }
              },
            )
            ..size = Vector2(segW * 0.96, towerH)
            ..position = Vector2(segW * (i + 0.02), floorY - towerH);

      parentContainer.add(tower);
    }
  }

  // Check team completion is handled inside _advanceCarBFS inside onComplete of the MoveEffect

  Future<void> _showSuccessLottie({required bool isTop}) async {
    final composition = await loadLottie(
      Lottie.asset('assets/images/arena/success_solved.json'),
    );
    final lottieComp = LottieComponent(composition, repeating: true)
      ..size = Vector2(250, 250)
      ..anchor = Anchor.center;

    // Exact center of the top or bottom half
    final halfHeight = size.y / 2;
    final centerX = size.x / 2;
    final centerY = isTop ? halfHeight / 2 : halfHeight + (halfHeight / 2);

    // We anchor it to the main arena so it stays centered even if towers are scrolled
    lottieComp.position = Vector2(centerX, centerY);

    if (isTop) {
      _topSuccessLottie = lottieComp;
      add(_topSuccessLottie!);
    } else {
      _bottomSuccessLottie = lottieComp;
      add(_bottomSuccessLottie!);
    }
  }



  @override
  void render(Canvas canvas) {
    // Clip the canvas so scrolled towers stay inside the rounded rectangle!
    canvas.clipRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(32)),
    );
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(32));

    // Background and border
    canvas.drawRRect(rrect, _bgPaint);
    canvas.drawRRect(rrect, _borderPaint);

    // Divider line
    final midY = size.y / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.x, midY), _dividerPaint);
  }
}
