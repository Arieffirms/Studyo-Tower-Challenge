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
                              insetPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Base design size for alert_game.png
                                  const baseW = 320.0;
                                  const baseH = 380.0;
                                  // Calculating scale based on available space maxing up to 500
                                  final double scale =
                                      (constraints.maxWidth > baseW
                                          ? baseW
                                          : constraints.maxWidth) /
                                      baseW;

                                  final double stackW = baseW * scale;
                                  final double stackH = baseH * scale;

                                  return Center(
                                    child: SizedBox(
                                      width: stackW,
                                      height: stackH,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/lobbies/alert_game.png',
                                            width: stackW,
                                            height: stackH,
                                            fit: BoxFit.fill,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF2D1B4E,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20 * scale,
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

                                          // Scaled positions and dimensions
                                          Positioned(
                                            top: 120 * scale,
                                            right: 80 * scale,
                                            child: SimpleImageButton(
                                              assetPath:
                                                  'assets/images/lobbies/play_online_button.png',
                                              width: 180 * scale,
                                              height: _btnH * scale,
                                              onClick: () {
                                                Get.back(); // Close main dialog
                                                Get.dialog(
                                                  Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    elevation: 0,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 32,
                                                            vertical: 40,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF2D1B4E,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white54,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .construction_rounded,
                                                            color: Color(
                                                              0xFF6DE0B2,
                                                            ),
                                                            size: 64,
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          const Text(
                                                            'Coming Soon!',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          const Text(
                                                            'Play Online feature is currently under development.',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 24,
                                                          ),
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xFFE53935,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              minimumSize:
                                                                  const Size(
                                                                    120,
                                                                    45,
                                                                  ),
                                                            ),
                                                            onPressed: () =>
                                                                Get.back(),
                                                            child: const Text(
                                                              'Close',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                          Positioned(
                                            top: 190 * scale,
                                            right: 100 * scale,
                                            child: SimpleImageButton(
                                              assetPath:
                                                  'assets/images/lobbies/play_komputer_button.png',
                                              width: 180 * scale,
                                              height: _btnH * scale,
                                              onClick: () {
                                                Get.back();
                                                controller.playVsComputer();
                                              },
                                            ),
                                          ),

                                          Positioned(
                                            top: 10 * scale,
                                            right: -45 * scale,
                                            child: SimpleImageButton(
                                              assetPath:
                                                  'assets/images/lobbies/close_alert_game.png',
                                              width: 180 * scale,
                                              height: _btnH * scale,
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
