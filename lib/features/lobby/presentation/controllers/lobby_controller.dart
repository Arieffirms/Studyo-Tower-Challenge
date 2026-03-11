import 'dart:async';
import 'package:get/get.dart';
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
  var secondsRemaining = 120.obs;
  Timer? _waitTimer;
  StreamSubscription? _lobbySubscription;

  @override
  void onClose() {
    _waitTimer?.cancel();
    _lobbySubscription?.cancel();
    super.onClose();
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
    try {
      // Default to Team A for player in vs Computer, or let them choose later
      final lobbyId = await createVsComputerLobbyUseCase(currentUser.playerId, 'A');
      currentLobbyId.value = lobbyId;
      _listenToLobby(lobbyId);
      // Wait a bit to simulate loading
      await Future.delayed(const Duration(seconds: 2));
      _navigateToGameMatch();
    } catch (e) {
      Get.snackbar('Error', 'Failed to start vs Computer match: \$e');
      isSearching.value = false;
    }
  }

  void _listenToLobby(String lobbyId) {
    _lobbySubscription?.cancel();
    _lobbySubscription = observeLobbyUseCase(lobbyId).listen((lobby) {
      activeLobby.value = lobby;
      
      if (lobby.status == 'starting' || lobby.status == 'running') {
        _waitTimer?.cancel();
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
        if (activeLobby.value != null && activeLobby.value!.status == 'waiting') {
           fillWithBotsUseCase(lobbyId, activeLobby.value!.playerIds.length);
        }
      }
    });
  }

  void _navigateToGameMatch() {
    // Navigate to the actual Game Screen when ready
    // e.g., Get.offNamed('/match', arguments: currentLobbyId.value);
    isSearching.value = false;
    Get.snackbar('Game Starting', 'Moving to arena!');
  }
}
