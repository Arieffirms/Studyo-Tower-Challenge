import '../repositories/i_tower_challenge_repository.dart';

/// Usecase to release a tower without solving it.
/// Called when player goes AFK or presses back on the SolveScreen.
class ReleaseTowerUseCase {
  final ITowerChallengeRepository repository;

  ReleaseTowerUseCase(this.repository);

  Future<void> call({
    required String matchId,
    required String teamId,
    required String towerId,
  }) async {
    await repository.releaseTower(
      matchId: matchId,
      teamId: teamId,
      towerId: towerId,
    );
  }
}
