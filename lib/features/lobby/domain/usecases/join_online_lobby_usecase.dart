import '../repositories/i_lobby_repository.dart';

class JoinOnlineLobbyUseCase {
  final ILobbyRepository repository;

  JoinOnlineLobbyUseCase(this.repository);

  Future<String> call(String playerId) async {
    return await repository.joinOnlineLobby(playerId);
  }
}
