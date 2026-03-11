import '../repositories/i_tower_challenge_repository.dart';

class InitializeMatchUseCase {
  final ITowerChallengeRepository repository;

  InitializeMatchUseCase(this.repository);

  Future<void> call(String matchId) async {
    await repository.initializeMatchState(matchId);
  }
}
