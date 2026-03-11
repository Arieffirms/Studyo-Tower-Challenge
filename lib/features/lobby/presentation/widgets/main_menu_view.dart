import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lobby_controller.dart';
import 'simple_image_button.dart';

// ─────────────────────────────────────────────
// Main Menu Screen
// ─────────────────────────────────────────────
class MainMenuView extends GetView<LobbyController> {
  const MainMenuView({super.key});

  // Layout constants — sama persis dengan Flame version
  static const double _btnW = 180;
  static const double _btnH = 55;
  static const double _btnGap = 16;
  static const double _menuPadX = 30;
  static const double _menuPadTop = 28;
  // static const double _menuPadBottom = 28;
  static const double _titleMenuGap = 80;
  static const double _titleH = 120;
  static const double _titleW = 300;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title / Logo ──────────────────────────────
          Image.asset(
            'assets/images/lobbies/logo-game.png',
            width: _titleW,
            height: _titleH,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: _titleW,
              height: _titleH,
              child: Center(
                child: Text('Logo Game', style: TextStyle(color: Colors.black)),
              ),
            ),
          ),

          const SizedBox(height: _titleMenuGap),

          // ── Menu Window membungkus buttons ────────────
          Stack(
            children: [
              // Background menu window image
              Image.asset(
                'assets/images/lobbies/menu_window.png',
                width: _btnW + _menuPadX * 2,
                height: 280,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: _btnW + _menuPadX * 2,
                  height: 280,
                  color: Colors.black12,
                ),
              ),

              // Buttons di atas menu window, dengan padding
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _menuPadX,
                    vertical: _menuPadTop,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 60),
                      SimpleImageButton(
                        assetPath: 'assets/images/lobbies/play_button.png',
                        width: 150,
                        height: _btnH,
                        onClick: () {
                          Get.dialog(
                            Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Gambar background alert
                                  Image.asset(
                                    'assets/images/lobbies/alert_game.png',
                                    width: 500,
                                    height: 450,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (
                                          context,
                                          error,
                                          stackTrace,
                                        ) => Container(
                                          width: 320,
                                          height: 240,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2D1B4E),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.white54,
                                              width: 2,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'alert_game.png\nbelum tersedia',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                  ),

                                  // Posisi tombol menyesuaikan tinggi gambar
                                  Positioned(
                                    top: 150,
                                    right: 80,
                                    child: SimpleImageButton(
                                      assetPath:
                                          'assets/images/lobbies/play_online_button.png',
                                      width: 180,
                                      height: _btnH,
                                      onClick: () {
                                        // TODO: implement Credits
                                      },
                                    ),
                                  ),

                                  Positioned(
                                    top: 220,
                                    right: 100,
                                    child: SimpleImageButton(
                                      assetPath:
                                          'assets/images/lobbies/play_komputer_button.png',
                                      width: 180,
                                      height: _btnH,
                                      onClick: () {
                                        // TODO: implement Credits
                                      },
                                    ),
                                  ),

                                  Positioned(
                                    top: 10,
                                    right: -35,
                                    child: SimpleImageButton(
                                      assetPath:
                                          'assets/images/lobbies/close_alert_game.png',
                                      width: 180,
                                      height: _btnH,
                                      onClick: () {
                                        Get.back();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: _btnGap),
                      SimpleImageButton(
                        assetPath: 'assets/images/lobbies/credits_button.png',
                        width: 150,
                        height: _btnH,
                        onClick: () {
                          // TODO: implement Credits
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
