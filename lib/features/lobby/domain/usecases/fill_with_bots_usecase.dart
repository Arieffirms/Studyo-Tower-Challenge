import '../repositories/i_lobby_repository.dart';

class FillWithBotsUseCase {
  final ILobbyRepository repository;

  FillWithBotsUseCase(this.repository);

  Future<void> call(String lobbyId, int currentPlayers) async {
    final botsNeeded = 8 - currentPlayers;
    if (botsNeeded > 0) {
      await repository.fillWithBots(lobbyId, botsNeeded);
    }
  }
}
