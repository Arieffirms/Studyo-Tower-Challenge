import '../repositories/i_tower_challenge_repository.dart';

class SolveTowerUseCase {
  final ITowerChallengeRepository repository;

  SolveTowerUseCase(this.repository);

  Future<void> call({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
    required int movesTaken,
    required int optimalMoves,
  }) async {
    await repository.solveTower(
      matchId: matchId,
      teamId: teamId,
      towerId: towerId,
      playerId: playerId,
      movesTaken: movesTaken,
      optimalMoves: optimalMoves,
    );
  }
}
