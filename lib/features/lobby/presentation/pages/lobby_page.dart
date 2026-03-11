import 'package:flutter/material.dart' hide Route;
import 'package:get/get.dart';
import '../controllers/lobby_controller.dart';
import '../widgets/main_menu_view.dart';
import '../widgets/searching_view.dart';

// ─────────────────────────────────────────────
// LobbyPage — root widget
// ─────────────────────────────────────────────
class LobbyPage extends GetView<LobbyController> {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient sama persis: kanan atas FBFBC4 → kiri bawah EBC0F5
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFFBFBC4), Color(0xFFEBC0F5)],
          ),
        ),
        child: Obx(() {
          // Toggle antara MainMenu dan Searching
          if (controller.isSearching.value) {
            return const SearchingView();
          }
          return const MainMenuView();
        }),
      ),
    );
  }
}
