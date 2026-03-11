import '../repositories/i_lobby_repository.dart';

class CreateVsComputerLobbyUseCase {
  final ILobbyRepository repository;

  CreateVsComputerLobbyUseCase(this.repository);

  Future<String> call(String playerId, String selectedTeam) async {
    return await repository.createVsComputerLobby(playerId, selectedTeam);
  }
}
