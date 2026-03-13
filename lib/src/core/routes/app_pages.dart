import 'package:get/get.dart';
import 'app_routes.dart';
import '../../../../features/lobby/presentation/pages/lobby_page.dart';
import '../bindings/lobby_binding.dart';
import '../../../../features/tower_challenge/presentation/pages/tower_challenge_page.dart';
import '../bindings/tower_challenge_binding.dart';

abstract class AppPages {
  static final pages = [
    GetPage(
      name: Routes.LOBBY,
      page: () => const LobbyPage(),
      binding: LobbyBinding(),
    ),
    GetPage(
      name: Routes.ARENA,
      page: () => const TowerChallengePage(),
      binding: TowerChallengeBinding(),
    ),
  ];
}
