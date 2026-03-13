import 'dart:async';
import 'package:flutter/material.dart' show Color;
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/usecases/join_online_lobby_usecase.dart';
import '../../domain/usecases/create_vs_computer_lobby_usecase.dart';
import '../../domain/usecases/observe_lobby_usecase.dart';
import '../../domain/usecases/fill_with_bots_usecase.dart';
import '../../../../src/core/entities/app_user_entity.dart';

class LobbyController extends GetxController {
  final JoinOnlineLobbyUseCase joinOnlineLobbyUseCase;
  final CreateVsComputerLobbyUseCase createVsComputerLobbyUseCase;
  final ObserveLobbyUseCase observeLobbyUseCase;
  final FillWithBotsUseCase fillWithBotsUseCase;

  // We should ideally get this from an Auth/User scope
  final AppUserEntity currentUser;

  // Add simulated count for vs Computer visual
  final vsComputerSimulatedCount = 1.obs;

  LobbyController({
    required this.joinOnlineLobbyUseCase,
    required this.createVsComputerLobbyUseCase,
    required this.observeLobbyUseCase,
    required this.fillWithBotsUseCase,
    required this.currentUser,
  });

  // UI State
  var isSearching = false.obs;
  var currentLobbyId = Rx<String?>(null);
  var activeLobby = Rx<LobbyEntity?>(null);

  // Timer State for 2 minute wait
  var secondsRemaining = 0.obs;
  Timer? _waitTimer;
  StreamSubscription? _lobbySubscription;

  @override
  void onClose() {
    _waitTimer?.cancel();
    _lobbySubscription?.cancel();
    super.onClose();
  }

  Future<void> cancelSearch() async {
    isSearching.value = false;
    _waitTimer?.cancel();
    _lobbySubscription?.cancel();

    if (currentLobbyId.value != null &&
        currentLobbyId.value != 'offline_match') {
      try {
        await FirebaseDatabase.instance
            .ref('liveMatches/${currentLobbyId.value}')
            .remove();
      } catch (e) {
        print('Failed to remove lobby: $e');
      }
    }

    currentLobbyId.value = null;
    activeLobby.value = null;
  }

  Future<void> joinOnlineMatchmaking() async {
    isSearching.value = true;
    try {
      final lobbyId = await joinOnlineLobbyUseCase(currentUser.playerId);
      currentLobbyId.value = lobbyId;
      _listenToLobby(lobbyId);
      _startWaitingTimer(lobbyId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to join matchmaking: \$e');
      isSearching.value = false;
    }
  }

  Future<void> playVsComputer() async {
    isSearching.value = true;
    vsComputerSimulatedCount.value = 1;

    try {
      // Create the match immediately on Firebase (background)
      final lobbyId = await createVsComputerLobbyUseCase(
        currentUser.playerId,
        '',
      );
      currentLobbyId.value = lobbyId;

      // Simulate visually bots joining one by one over 10 seconds
      // (1 -> 3 -> 5 -> 7 -> 8)
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (!isSearching.value) return; // Abort if user cancelled

        secondsRemaining.value = i; // Count up: 00:01 ... 00:10

        if (i == 2) vsComputerSimulatedCount.value = 3;
        if (i == 5) vsComputerSimulatedCount.value = 5;
        if (i == 8) vsComputerSimulatedCount.value = 7;
        if (i == 10) vsComputerSimulatedCount.value = 8;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (!isSearching.value) return; // Abort if cancelled during delay
      _navigateToGameMatch();
    } catch (e) {
      Get.snackbar(
        'Database Error',
        "Failed to save to Firebase: ${e.toString().split('\\n').first}",
        backgroundColor: const Color(0xFFB91C1C),
        colorText: const Color(0xFFFFFFFF),
      );
      print("database error: ${e.toString().split('\\n').first}");
      // Fallback: Tetap navigasi ke Arena meskipun Firebase error (Offline mode)
      currentLobbyId.value = 'offline_match';
      await Future.delayed(const Duration(seconds: 1));
      if (!isSearching.value) return; // Abort if cancelled during delay
      _navigateToGameMatch();
    }
  }

  void _listenToLobby(String lobbyId) {
    _lobbySubscription?.cancel();
    _lobbySubscription = observeLobbyUseCase(lobbyId).listen((lobby) {
      activeLobby.value = lobby;

      if (lobby.status == 'starting' || lobby.status == 'running') {
        _waitTimer?.cancel();
        if (!isSearching.value) return;
        _navigateToGameMatch();
      }
    });
  }

  void _startWaitingTimer(String lobbyId) {
    secondsRemaining.value = 120;
    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
        // 2 minutes passed, fill with bots if still in lobby waiting
        if (activeLobby.value != null &&
            activeLobby.value!.status == 'waiting') {
          fillWithBotsUseCase(lobbyId, activeLobby.value!.playerIds.length);
        }
      }
    });
  }

  void _navigateToGameMatch() {
    // Route ke halaman Game Arena sambil mengirim Argument berupa ID Lobby
    isSearching.value = false;
    Get.offNamed(
      '/arena',
      arguments: {'lobbyId': currentLobbyId.value, 'uid': currentUser.playerId},
    );
  }
}
