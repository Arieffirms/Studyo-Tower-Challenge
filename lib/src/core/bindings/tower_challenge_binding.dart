import 'package:get/get.dart';
import '../../../features/tower_challenge/data/datasources/tower_challenge_remote_datasource.dart';
import '../../../features/tower_challenge/data/repositories/tower_challenge_repository_impl.dart';
import '../../../features/tower_challenge/domain/usecases/claim_tower_usecase.dart';
import '../../../features/tower_challenge/domain/usecases/solve_tower_usecase.dart';
import '../../../features/tower_challenge/domain/usecases/release_tower_usecase.dart';
import '../../../features/tower_challenge/domain/usecases/observe_players_usecase.dart';
import '../../../features/tower_challenge/presentation/controllers/arena_controller.dart';

class TowerChallengeBinding extends Bindings {
  @override
  void dependencies() {
    // ── Data layer ────────────────────────────────────────────────────────────
    Get.lazyPut<TowerChallengeRemoteDataSource>(
      () => TowerChallengeRemoteDataSourceImpl(),
    );

    Get.lazyPut<TowerChallengeRepositoryImpl>(
      () => TowerChallengeRepositoryImpl(
        dataSource: Get.find<TowerChallengeRemoteDataSource>()
            as TowerChallengeRemoteDataSourceImpl,
      ),
    );

    // ── Domain usecases ───────────────────────────────────────────────────────
    Get.lazyPut<ClaimTowerUseCase>(
      () => ClaimTowerUseCase(Get.find<TowerChallengeRepositoryImpl>()),
    );
    Get.lazyPut<SolveTowerUseCase>(
      () => SolveTowerUseCase(Get.find<TowerChallengeRepositoryImpl>()),
    );
    Get.lazyPut<ReleaseTowerUseCase>(
      () => ReleaseTowerUseCase(Get.find<TowerChallengeRepositoryImpl>()),
    );
    Get.lazyPut<ObservePlayersUseCase>(
      () => ObservePlayersUseCase(Get.find<TowerChallengeRepositoryImpl>()),
    );

    // ── Presentation ──────────────────────────────────────────────────────────
    Get.lazyPut<ArenaController>(
      () => ArenaController(
        repository: Get.find<TowerChallengeRepositoryImpl>(),
        claimTowerUseCase: Get.find<ClaimTowerUseCase>(),
        solveTowerUseCase: Get.find<SolveTowerUseCase>(),
        releaseTowerUseCase: Get.find<ReleaseTowerUseCase>(),
        observePlayersUseCase: Get.find<ObservePlayersUseCase>(),
      ),
    );
  }
}
