import '../../domain/entities/lobby_entity.dart';
import '../../domain/repositories/i_lobby_repository.dart';
import '../datasources/lobby_remote_datasource.dart';
import '../models/player_model.dart';

class LobbyRepositoryImpl implements ILobbyRepository {
  final LobbyRemoteDataSource remoteDataSource;

  LobbyRepositoryImpl(this.remoteDataSource);

  @override
  Future<String> joinOnlineLobby(String playerId) async {
    // Create a temporary player model to send to data source
    // At this stage, team is usually unassigned
    final player = PlayerModel(
      playerId: playerId,
      displayName: 'Player $playerId', // Real name would come from auth/prefs
      team: '',
      isBot: false,
    );
    return await remoteDataSource.joinOnlineLobby(player);
  }

  @override
  Future<String> createVsComputerLobby(
    String playerId,
    String selectedTeam,
  ) async {
    final player = PlayerModel(
      playerId: playerId,
      displayName: 'Player $playerId',
      team: selectedTeam,
      isBot: false,
    );
    return await remoteDataSource.createVsComputerLobby(player);
  }

  @override
  Stream<LobbyEntity> observeLobby(String lobbyId) {
    return remoteDataSource.observeLobby(lobbyId);
  }

  @override
  Future<void> fillWithBots(String lobbyId, int botsToAdd) async {
    await remoteDataSource.fillWithBots(lobbyId, botsToAdd);
  }

  @override
  Future<void> leaveLobby(String lobbyId, String playerId) async {
    await remoteDataSource.leaveLobby(lobbyId, playerId);
  }
}
