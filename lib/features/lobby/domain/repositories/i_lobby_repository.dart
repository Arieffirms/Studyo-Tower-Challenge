import '../entities/lobby_entity.dart';

abstract class ILobbyRepository {
  /// Join an existing online lobby or create a new one if none available.
  Future<String> joinOnlineLobby(String playerId);

  /// Create a fresh lobby specifically for Vs Computer mode.
  Future<String> createVsComputerLobby(String playerId, String selectedTeam);

  /// Observe the state of the current lobby (players joining, status changes).
  Stream<LobbyEntity> observeLobby(String lobbyId);

  /// Fill the remaining slots in the lobby with AI bots.
  Future<void> fillWithBots(String lobbyId, int botsToAdd);

  /// Leave the matchmaking lobby.
  Future<void> leaveLobby(String lobbyId, String playerId);
}
