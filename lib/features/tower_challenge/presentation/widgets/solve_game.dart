import 'dart:async' as async_io;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame_lottie/flame_lottie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'solve_flame_components.dart';

// ═════════════════════════════════════════════════════════════════
//  FLAME GAME (The entire UI matching the mockup)
// ═════════════════════════════════════════════════════════════════
class SolveGame extends FlameGame {
  final VoidCallback onBack;
  final void Function(int moves, int time) onSolved;
  final int initialScore;

  int _current;
  int _moves = 0;
  // seconds left on timer (synced from Arena)
  int _remainingSeconds;
  async_io.Timer? _ticker;
  bool _finished = false;

  int _afkSeconds = 0;
  bool _isShowingAfkWarning = false;
  async_io.Timer? _cancelAfkTimer;

  late TextComponent _currentLabel;
  late TextComponent _movesLabel;
  late TextComponent _timerLabel;
  late PositionComponent _playerTowerComp;

  static const int _target = 1000;

  SolveGame({
    required this.onBack,
    required this.onSolved,
    required this.initialScore,
    required int remainingSeconds,
  }) : _current = initialScore,
       _remainingSeconds = remainingSeconds;

  @override
  Color backgroundColor() => const Color(0xFFF5EDD8); // Cream background

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Size of the game screen
    final gs = size;

    // ── Top Bar Elements (Y = 16) ────────────────────────────────
    const topY = 12.0;

    // Back & Restart Buttons
    try {
      final backSprite = await Sprite.load('arena/button_back.png');
      add(
        SolveTapButton(
          sprite: backSprite,
          size: Vector2(70, 65),
          position: Vector2(16 + 35, topY + 32),
          onTap: onBack,
        ),
      );
    } catch (_) {}

    try {
      final restartSprite = await Sprite.load('arena/button_restart.png');
      add(
        SolveTapButton(
          sprite: restartSprite,
          size: Vector2(70, 65),
          position: Vector2(80 + 50, topY + 32),
          onTap: () {
            _current = initialScore;
            _moves = 0;
            _movesLabel.text = '0';
            _rebuildPlayerTower(animate: true);
          },
        ),
      );
    } catch (_) {}

    // Move & Time Indicators (Right aligned)
    final rightX = gs.x;
    try {
      final moveSprite = await Sprite.load('arena/indicator_move.png');
      // put the move indicator in the centre of its allowed slot
      final moveComp = SpriteComponent(
        sprite: moveSprite,
        size: Vector2(70, 65),
        anchor: Anchor.center,
        position: Vector2(rightX - 58, topY + 35),
      );
      add(moveComp);
      _movesLabel = TextComponent(
        text: '0',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.center,
        // align exactly with the sprite's centre
        position: Vector2(rightX - 58, topY + 35),
      );
      add(_movesLabel);
    } catch (_) {}

    try {
      final timeSprite = await Sprite.load('arena/inidicator_time.png');
      final timeComp = SpriteComponent(
        sprite: timeSprite,
        size: Vector2(70, 65),
        anchor: Anchor.center,
        // move the time indicator further left and slightly lower
        position: Vector2(rightX - 170 + 40 - 10, topY + 34),
      );
      add(timeComp);
      _timerLabel = TextComponent(
        text: _formatTime(_remainingSeconds),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(rightX - 170 + 40 - 10, topY + 34),
      );
      add(_timerLabel);
    } catch (_) {}

    // ── Teal solve card ──────────────────────────────────────────
    final tealTop = topY + 80.0;
    final tealH = gs.y - tealTop - 20.0; // Extend to near bottom
    final tealW = gs.x - 32;
    final tealLeft = 16.0;

    add(
      SolveRoundedRect(
        size: Vector2(tealW, tealH),
        position: Vector2(tealLeft, tealTop),
        color: const Color(0xFF6ED7C5),
      ),
    );

    // ── Purple floor inside card ────────────────────────────────
    final floorH = 140.0; // Taller floor to fit buttons
    final floorTop = tealTop + tealH - floorH;

    // Bottom part of the card is the purple floor (rounded bottom)
    final floorComp = PositionComponent(
      size: Vector2(tealW, floorH),
      position: Vector2(tealLeft, floorTop),
    );
    // Draw purple floor with rounded bottom corners
    floorComp.add(
      RectangleComponent(
        size: Vector2(tealW, floorH - 24),
        position: Vector2(0, 0),
        paint: Paint()..color = const Color(0xFF7D59A4),
      ),
    );
    floorComp.add(
      CircleComponent(
        radius: 24,
        position: Vector2(0, floorH - 48),
        paint: Paint()..color = const Color(0xFF7D59A4),
      ),
    );
    floorComp.add(
      CircleComponent(
        radius: 24,
        position: Vector2(tealW - 48, floorH - 48),
        paint: Paint()..color = const Color(0xFF7D59A4),
      ),
    );
    floorComp.add(
      RectangleComponent(
        size: Vector2(tealW - 48, 24),
        position: Vector2(24, floorH - 24),
        paint: Paint()..color = const Color(0xFF7D59A4),
      ),
    );
    floorComp.add(
      RectangleComponent(
        size: Vector2(tealW, floorH - 24),
        position: Vector2(0, 0),
        paint: Paint()..color = const Color(0xFF7D59A4),
      ),
    );
    add(floorComp);

    // ── +10 and x2 Buttons inside Purple Floor ──────────────────
    final btnCenterY = floorTop + floorH / 2;
    final btnW = (tealW / 2) - 24;
    final btnH = 85.0;

    try {
      final plusSprite = await Sprite.load('arena/button_plus_ten.png');
      add(
        SolveTapButton(
          sprite: plusSprite,
          size: Vector2(btnW, btnH),
          position: Vector2(tealLeft + 16 + btnW / 2, btnCenterY),
          onTap: _onPlusTen,
        ),
      );
    } catch (_) {}

    try {
      final x2Sprite = await Sprite.load('arena/button_x_two.png');
      add(
        SolveTapButton(
          sprite: x2Sprite,
          size: Vector2(btnW, btnH),
          position: Vector2(tealLeft + tealW - 16 - btnW / 2, btnCenterY),
          onTap: _onTimesTwo,
        ),
      );
    } catch (_) {}

    // ── Target tower (left, 1000) ───────────────────────────────
    final maxTowerH = tealH - floorH - 200; // padding from top of teal card
    const targetW = 60.0;

    final targetTower = PositionComponent(
      size: Vector2(targetW, maxTowerH),
      position: Vector2(tealLeft, floorTop - maxTowerH),
    );
    targetTower.add(
      RectangleComponent(
        size: Vector2(targetW, maxTowerH),
        paint: Paint()..color = const Color(0xFF7D59A4),
      ),
    );
    add(targetTower);

    // Car on top of target
    try {
      final comp = await loadLottie(
        Lottie.asset('assets/images/arena/car_solved.json'),
      );
      final car = LottieComponent(comp, repeating: true)
        ..size = Vector2(100, 100);
      car.position = Vector2(-19, -58);
      targetTower.add(car);
    } catch (_) {}

    targetTower.add(
      TextComponent(
        text: '$_target',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(8, 8),
      ),
    );

    // ── Player tower (right, grows) ─────────────────────────────
    _playerTowerComp = PositionComponent();
    add(_playerTowerComp);
    _rebuildPlayerTower(animate: false);

    // ── Start timer ──────────────────────────────────────────────
    _ticker = async_io.Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_finished && !_isShowingAfkWarning) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _updateTimerLabel();

          if (_remainingSeconds <= 0) {
            // Match is over! Pop the solve screen to let ArenaBoard show results
            onBack();
          }
        }

        _afkSeconds++;
        if (_afkSeconds >= 30) {
          _showAfkWarning();
        }
      }
    });
  }

  void _showAfkWarning() {
    if (_isShowingAfkWarning) return;
    _isShowingAfkWarning = true;

    // Give 15 seconds to respond, otherwise kick
    _cancelAfkTimer = async_io.Timer(const Duration(seconds: 15), () {
      if (_isShowingAfkWarning) {
        if (Get.isDialogOpen ?? false) Get.back(); // close dialog
        onBack(); // close solve screen
      }
    });

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Are You AFK?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You have been inactive for 30 seconds. Click continue so you don\'t lose this tower.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6DE0B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  _isShowingAfkWarning = false;
                  _afkSeconds = 0;
                  _cancelAfkTimer?.cancel();
                  if (Get.isDialogOpen ?? false) Get.back(); // close dialog
                },
                child: const Text(
                  'Continue Playing',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ─── Rebuild player tower ───────────────────────────────────────
  void _rebuildPlayerTower({required bool animate}) {
    final oldHeight = _playerTowerComp.size.y;
    _playerTowerComp.removeAll(_playerTowerComp.children.toList());

    final gs = size;
    const topY = 16.0;
    final tealTop = topY + 80.0;
    final tealH = gs.y - tealTop - 20.0;
    final floorH = 140.0;
    final floorTop = tealTop + tealH - floorH;
    final tealLeft = 10.0;

    final maxTowerH = tealH - floorH - 200;
    final frac = (_current / _target).clamp(0.0, 1.0);
    final targetH = (maxTowerH * frac).clamp(30.0, maxTowerH);

    final towerW = gs.x - 32 - 40 - 50;
    final xPos = tealLeft + 20 + 45 + 16;

    _playerTowerComp.size = Vector2(towerW, targetH);
    _playerTowerComp.position = Vector2(xPos, floorTop - targetH);

    final rect = RectangleComponent(
      size: Vector2(towerW, targetH),
      paint: Paint()..color = const Color(0xFF7D59A4),
    );
    _playerTowerComp.add(rect);

    // label now uses center anchor so it stays in the middle of the tower
    _currentLabel = TextComponent(
      text: '$_current',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(towerW / 2, targetH / 2),
    );
    _playerTowerComp.add(_currentLabel);

    if (animate) {
      _playerTowerComp.position.y = floorTop - oldHeight;
      rect.size.y = oldHeight;
      // start the label at centre of old height, then animate it too
      _currentLabel.position = Vector2(towerW / 2, oldHeight / 2);

      _playerTowerComp.add(
        MoveEffect.to(
          Vector2(xPos, floorTop - targetH),
          EffectController(duration: 0.15, curve: Curves.easeOut),
        ),
      );
      rect.add(
        SizeEffect.to(
          Vector2(towerW, targetH),
          EffectController(duration: 0.15, curve: Curves.easeOut),
        ),
      );
      _currentLabel.add(
        MoveEffect.to(
          Vector2(towerW / 2, targetH / 2),
          EffectController(duration: 0.15, curve: Curves.easeOut),
        ),
      );
    }
  }

  // ─── Animation Effects ──────────────────────────────────────────
  void _shakePlayerTower() {
    _playerTowerComp.add(
      MoveEffect.by(
        Vector2(8, 0),
        EffectController(duration: 0.05, repeatCount: 4, reverseDuration: 0.05),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────
  void _onPlusTen() {
    if (_finished || _isShowingAfkWarning) return;
    _afkSeconds = 0; // Reset AFK timer on action
    final next = _current + 10;
    _moves++;
    _movesLabel.text = '$_moves';

    if (next > _target) {
      _shakePlayerTower();
      _current = initialScore; // failure should also clear moves
      _moves = 0;
      _movesLabel.text = '0'; // reset without animation so label stays centred
      _rebuildPlayerTower(animate: false);
      return;
    }

    _current = next;
    _rebuildPlayerTower(animate: true);
    if (_current == _target) _onComplete();
  }

  void _onTimesTwo() {
    if (_finished || _isShowingAfkWarning) return;
    _afkSeconds = 0; // Reset AFK timer on action
    final next = _current * 2;
    _moves++;
    _movesLabel.text = '$_moves';

    if (next > _target) {
      _shakePlayerTower();
      _current = initialScore;
      // failure should also clear moves
      _moves = 0;
      _movesLabel.text = '0';
      // same reset behaviour: no animation
      _rebuildPlayerTower(animate: false);
      return;
    }

    _current = next;
    _rebuildPlayerTower(animate: true);
    if (_current == _target) _onComplete();
  }

  void _onComplete() async {
    _finished = true;
    _ticker?.cancel();

    try {
      final comp = await loadLottie(
        Lottie.asset('assets/images/arena/congratulation.json'),
      );
      final confetti = LottieComponent(comp, repeating: false)..size = size;
      confetti.position = Vector2.zero();
      add(confetti);
    } catch (_) {}

    Future.delayed(
      const Duration(milliseconds: 1500),
      () => onSolved(_moves, _remainingSeconds),
    );
  }

  void _updateTimerLabel() {
    _timerLabel.text = _formatTime(_remainingSeconds);
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  void onRemove() {
    _cancelAfkTimer?.cancel();
    _ticker?.cancel();
    super.onRemove();
  }
}
