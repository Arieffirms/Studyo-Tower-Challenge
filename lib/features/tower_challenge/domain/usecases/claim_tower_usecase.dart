import '../repositories/i_tower_challenge_repository.dart';

class ClaimTowerUseCase {
  final ITowerChallengeRepository repository;

  ClaimTowerUseCase(this.repository);

  Future<bool> call({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
  }) async {
    return await repository.claimTower(
      matchId: matchId,
      teamId: teamId,
      towerId: towerId,
      playerId: playerId,
    );
  }
}
