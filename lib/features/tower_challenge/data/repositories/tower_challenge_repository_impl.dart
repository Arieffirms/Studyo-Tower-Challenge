import 'dart:async';
import '../../domain/entities/match_entity.dart';
import '../../domain/entities/bot_configuration_entity.dart';
import '../../domain/repositories/i_tower_challenge_repository.dart';
import '../datasources/tower_challenge_remote_datasource.dart';
import '../models/arena_player_model.dart';

/// Concrete implementation of [ITowerChallengeRepository].
/// Delegates all calls to [TowerChallengeRemoteDataSource].
class TowerChallengeRepositoryImpl implements ITowerChallengeRepository {
  final TowerChallengeRemoteDataSource dataSource;

  TowerChallengeRepositoryImpl({required this.dataSource});

  @override
  Stream<MatchEntity> observeMatch(String matchId) {
    // Full match observation not implemented yet — currently players-only stream is used.
    // This stub satisfies the domain interface. Expand when MatchEntity is fully wired.
    throw UnimplementedError(
      'observeMatch: use observePlayers() and fetchMatchMeta() directly via the controller.',
    );
  }

  @override
  Future<bool> claimTower({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
  }) => dataSource.claimTower(
    matchId: matchId,
    teamId: teamId,
    towerId: towerId,
    playerId: playerId,
  );

  @override
  Future<void> solveTower({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
    required int movesTaken,
    required int optimalMoves,
  }) => dataSource.solveTower(
    matchId: matchId,
    teamId: teamId,
    towerId: towerId,
    playerId: playerId,
    movesTaken: movesTaken,
  );

  @override
  Future<void> releaseTower({
    required String matchId,
    required String teamId,
    required String towerId,
  }) => dataSource.releaseTower(
    matchId: matchId,
    teamId: teamId,
    towerId: towerId,
  );

  @override
  Future<void> initializeMatchState(String matchId) async {
    // Match initialization is handled at lobby creation time.
    // Stub satisfies the interface.
  }

  @override
  Future<List<BotConfigurationEntity>> getActiveBots(String matchId) async {
    // Bot configs are derived from the observable player stream in ArenaController.
    return [];
  }

  /// Expose player stream without going through MatchEntity (used by ArenaController).
  Stream<Map<String, ArenaPlayerModel>> observePlayers(String matchId) =>
      dataSource.observePlayers(matchId);

  /// Sends a heartbeat for the human player.
  Future<void> updateHeartbeat(String matchId, String uid) =>
      dataSource.updateHeartbeat(matchId, uid);

  /// Fetches match meta (status, startAt, durationSec).
  Future<Map<String, dynamic>?> fetchMatchMeta(String matchId) =>
      dataSource.fetchMatchMeta(matchId);

  /// Simulates a bot's stat update.
  Future<void> simulateBotMove({
    required String matchId,
    required String botId,
    required int movesToAdd,
  }) => dataSource.simulateBotMove(
    matchId: matchId,
    botId: botId,
    movesToAdd: movesToAdd,
  );

  @override
  Future<void> assignTeamAndBalanceBots(
    String matchId,
    String uid,
    String team,
  ) async {
    await dataSource.assignTeamAndBalanceBots(matchId, uid, team);
  }

  @override
  Future<void> updateTeamScores(String matchId, int scoreA, int scoreB) =>
      dataSource.updateTeamScores(matchId, scoreA, scoreB);
}
