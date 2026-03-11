import 'dart:math';
import 'package:get/get.dart';
import '../../../features/lobby/data/datasources/lobby_remote_datasource.dart';
import '../../../features/lobby/data/repositories/lobby_repository_impl.dart';
import '../../../features/lobby/domain/usecases/join_online_lobby_usecase.dart';
import '../../../features/lobby/domain/usecases/create_vs_computer_lobby_usecase.dart';
import '../../../features/lobby/domain/usecases/observe_lobby_usecase.dart';
import '../../../features/lobby/domain/usecases/fill_with_bots_usecase.dart';
import '../../../features/lobby/presentation/controllers/lobby_controller.dart';
import '../entities/app_user_entity.dart';

class LobbyBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Data Sources
    Get.lazyPut<LobbyRemoteDataSource>(() => LobbyRemoteDataSourceImpl());

    // 2. Repositories
    Get.lazyPut(() => LobbyRepositoryImpl(Get.find<LobbyRemoteDataSource>()));

    // 3. Use Cases
    Get.lazyPut(() => JoinOnlineLobbyUseCase(Get.find<LobbyRepositoryImpl>()));
    Get.lazyPut(
      () => CreateVsComputerLobbyUseCase(Get.find<LobbyRepositoryImpl>()),
    );
    Get.lazyPut(() => ObserveLobbyUseCase(Get.find<LobbyRepositoryImpl>()));
    Get.lazyPut(() => FillWithBotsUseCase(Get.find<LobbyRepositoryImpl>()));

    // 4. Controller
    Get.lazyPut(
      () => LobbyController(
        joinOnlineLobbyUseCase: Get.find(),
        createVsComputerLobbyUseCase: Get.find(),
        observeLobbyUseCase: Get.find(),
        fillWithBotsUseCase: Get.find(),
        // Mocking Current User dengan random ID (tanpa login system)
        currentUser: AppUserEntity(
          playerId: 'user_\${Random().nextInt(99999)}',
          displayName: 'Guest\${Random().nextInt(9999)}',
        ),
      ),
    );
  }
}
