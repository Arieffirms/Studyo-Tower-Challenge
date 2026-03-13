import '../../data/repositories/tower_challenge_repository_impl.dart';
import '../../data/models/arena_player_model.dart';

/// Usecase to observe all players in a match as a real-time stream.
class ObservePlayersUseCase {
  final TowerChallengeRepositoryImpl repository;

  ObservePlayersUseCase(this.repository);

  Stream<Map<String, ArenaPlayerModel>> call(String matchId) {
    return repository.observePlayers(matchId);
  }
}
