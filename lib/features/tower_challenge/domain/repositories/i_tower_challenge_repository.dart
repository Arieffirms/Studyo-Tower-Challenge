import '../entities/match_entity.dart';
import '../entities/bot_configuration_entity.dart';

abstract class ITowerChallengeRepository {
  /// Stream the real-time state of the entire match (teams, scores, towers).
  Stream<MatchEntity> observeMatch(String matchId);

  /// Attempt to claim a tower for a specific player.
  /// Returns true if successful, false if already claimed or unavailable.
  Future<bool> claimTower({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
  });

  /// Submit a solved result for a tower.
  Future<void> solveTower({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
    required int movesTaken,
    required int optimalMoves,
  });

  /// Release a claimed tower without solving it (e.g., player exits overlay or goes AFK).
  Future<void> releaseTower({
    required String matchId,
    required String teamId,
    required String towerId,
  });

  /// Initialize the match state in Firebase (setup target, 20 towers for both teams, transfer from lobby).
  Future<void> initializeMatchState(String matchId);
  
  /// Get all active bots for a specific match.
  Future<List<BotConfigurationEntity>> getActiveBots(String matchId);

  /// Assign team to player and balance bots
  Future<void> assignTeamAndBalanceBots(String matchId, String uid, String team);

  /// Updates final team scores in Firebase
  Future<void> updateTeamScores(String matchId, int scoreA, int scoreB);
}
