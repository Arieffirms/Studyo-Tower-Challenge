import '../repositories/i_tower_challenge_repository.dart';
import '../entities/bot_configuration_entity.dart';
import '../entities/tower_entity.dart';

/// Business logic for a bot deciding to move, claim, and solve a tower.
class BotMoveUseCase {
  final ITowerChallengeRepository repository;

  BotMoveUseCase(this.repository);

  Future<void> call(
    String matchId,
    BotConfigurationEntity bot,
    List<TowerEntity> availableTowers,
  ) async {
    if (availableTowers.isEmpty) return;

    // Simulate finding a random tower to claim
    availableTowers.shuffle();
    final targetTower = availableTowers.first;

    final success = await repository.claimTower(
      matchId: matchId,
      teamId: bot.team,
      towerId: targetTower.id,
      playerId: bot.botId,
    );

    if (success) {
      // Simulation of a bot solving the tower (can be expanded)
      // Generally handled externally or via an isolate scheduler.
    }
  }
}
