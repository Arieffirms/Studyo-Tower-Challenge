import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Rounded-rect helper
// ─────────────────────────────────────────────
class SolveRoundedRect extends PositionComponent {
  final Color color;
  final double radius;
  final bool bottomFlat;

  SolveRoundedRect({
    required Vector2 size,
    required Vector2 position,
    required this.color,
    this.radius = 24,
    this.bottomFlat = false,
  }) : super(size: size, position: position);

  @override
  void render(Canvas canvas) {
    if (bottomFlat) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          size.toRect(),
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
        Paint()..color = color,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, size.y - radius, size.x, radius),
        Paint()..color = color,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(size.toRect(), Radius.circular(radius)),
        Paint()..color = color,
      );
    }
  }
}

// ─────────────────────────────────────────────
//  Tap-able Sprite Button
// ─────────────────────────────────────────────
class SolveTapButton extends SpriteComponent with TapCallbacks {
  final VoidCallback onTap;
  
  SolveTapButton({
    required Sprite sprite,
    required Vector2 size,
    required this.onTap,
    Vector2? position,
  }) : super(
         sprite: sprite,
         size: size,
         anchor: Anchor.center,
         position: position,
       );

  @override
  void onTapDown(TapDownEvent e) => scale = Vector2.all(0.88);
  
  @override
  void onTapUp(TapUpEvent e) {
    scale = Vector2.all(1.0);
    onTap();
  }

  @override
  void onTapCancel(TapCancelEvent e) => scale = Vector2.all(1.0);
}
