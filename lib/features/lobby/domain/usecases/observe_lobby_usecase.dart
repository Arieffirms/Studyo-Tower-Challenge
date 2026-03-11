import '../repositories/i_lobby_repository.dart';
import '../entities/lobby_entity.dart';

class ObserveLobbyUseCase {
  final ILobbyRepository repository;

  ObserveLobbyUseCase(this.repository);

  Stream<LobbyEntity> call(String lobbyId) {
    return repository.observeLobby(lobbyId);
  }
}
