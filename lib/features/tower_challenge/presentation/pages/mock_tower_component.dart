import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart'; // Added for resize/move effects
import 'package:flame_lottie/flame_lottie.dart';
import 'package:flutter/material.dart';

/// Single source of truth for each tower's lifecycle state.
/// idle    → shows + icon (available to claim)
/// working → shows typing.json (locked while being solved)
/// solved  → blue tower full, no + or typing, cleared
enum TowerState { idle, working, solved }

class BounceSpriteButton extends SpriteComponent with TapCallbacks {
  final VoidCallback? onPressed;

  BounceSpriteButton({
    required Sprite sprite,
    required Vector2 size,
    required Vector2 position,
    this.onPressed,
  }) : super(sprite: sprite, size: size, position: position) {
    // Set anchor to center so it shrinks towards the middle, not top-left
    anchor = Anchor.center;
    // Adjust position since parent gave us top-left coordinates
    this.position = position + (size / 2);
  }

  @override
  void onTapDown(TapDownEvent event) {
    scale = Vector2.all(0.85); // Shrink visually to simulate bounce down
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0); // Restore size
    onPressed?.call();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    scale = Vector2.all(1.0); // Restore size if dragged away
  }
}

class MockTowerComponent extends PositionComponent {
  final int id;
  final Color color;
  final Color? topColor;
  final Color? topColor2;
  String label;
  bool hasCar;
  String avatarName;
  bool isPlus;
  bool hasParticles;
  bool isAFK;

  /// Current state of this tower — drives validation and visual guards
  TowerState towerState = TowerState.idle;
  final VoidCallback? onPlusTapped;

  MockTowerComponent({
    required this.id,
    required this.color,
    this.topColor,
    this.topColor2,
    this.label = '',
    this.hasCar = false,
    this.avatarName = '',
    this.isPlus = false,
    this.hasParticles = false,
    this.isAFK = false,
    this.onPlusTapped,
  });

  bool _lottieFailed = false;
  Sprite? _avatarSprite;
  RectangleComponent? _blueTower;
  RectangleComponent? _blueTop; // grey cap that sits on top of blue progress
  LottieComponent? _carComponent;
  LottieComponent? _particlesComponent;

  void setBlueProgress(double targetHeight) {
    if (_blueTower == null) {
      if (targetHeight <= 0) return;
      // choose a random overlay colour when the tower first appears
      final rand = Random();
      final randomColor = Color.fromARGB(
        255,
        rand.nextInt(256),
        rand.nextInt(256),
        rand.nextInt(256),
      ).withOpacity(0.75);

      _blueTower = RectangleComponent(
        size: Vector2(size.x, 0), // Matches purple base width perfectly
        position: Vector2(0, 0), // Centered
        anchor: Anchor.bottomLeft, // Grows upwards from the roof!
        paint: Paint()..color = randomColor,
      );
      add(_blueTower!);
      // add a thin grey cap that will always stick to the top of the blue tower
      _blueTop = RectangleComponent(
        size: Vector2(size.x, 6),
        position: Vector2(0, 0),
        anchor: Anchor.bottomLeft,
        paint: Paint()..color = Colors.grey,
      );
      add(_blueTop!);
    }

    if (targetHeight > 0 && (targetHeight - _blueTower!.size.y).abs() > 1.0) {
      final existingEffects = _blueTower!.children.whereType<SizeEffect>();
      if (existingEffects.isEmpty) {
        _blueTower!.add(
          SizeEffect.to(
            Vector2(
              size.x,
              targetHeight,
            ), // Ensure width matches _blueTower size
            EffectController(duration: 0.5, curve: Curves.easeOut),
          ),
        );
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Typing animation follows the tip of the blue tower (shows above active work area)
    if (_particlesComponent != null && _blueTower != null) {
      _particlesComponent!.position.y = -_blueTower!.size.y - 55;
    }
    // keep grey cap sitting at top of blue tower
    if (_blueTop != null && _blueTower != null) {
      // keep the cap slightly lower by the inset amount
      _blueTop!.position.y = -_blueTower!.size.y + 5;
    }
    // Car stays at its FIXED height — only moves horizontally via MoveEffect on solve
  }

  void stopParticles() {
    _particlesComponent?.removeFromParent();
    _particlesComponent = null;
    hasParticles = false;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (hasCar) {
      final composition = await loadLottie(
        Lottie.asset('assets/images/arena/car_solved.json'),
      );
      _carComponent = LottieComponent(composition, repeating: true)
        ..size = Vector2(100, 100);
      _carComponent!.position = Vector2(size.x / 2 - 50, -60);
      add(_carComponent!);
    }

    if (hasParticles) {
      try {
        final typingComposition = await loadLottie(
          Lottie.asset('assets/images/arena/typing.json'),
        );
        _particlesComponent = LottieComponent(
          typingComposition,
          repeating: true,
        )..size = Vector2(100, 100);

        _particlesComponent!.position = Vector2(size.x / 2 - 50, -60);
        add(_particlesComponent!);
      } catch (e) {
        debugPrint('Typing Lottie failed to load: $e');
      }
    }

    if (avatarName.isNotEmpty) {
      final random = Random();
      final avatarIndex = random.nextInt(4) + 1; // random 1 to 8
      try {
        _avatarSprite = await Sprite.load('arena/user_$avatarIndex.png');
      } catch (e) {
        debugPrint('Failed to load avatar arena/user_$avatarIndex.png: $e');
      }
    }

    if (isPlus) {
      try {
        final _addIconSprite = await Sprite.load('arena/add_solved.png');
        final btn = BounceSpriteButton(
          sprite: _addIconSprite,
          onPressed: onPlusTapped,
          size: Vector2(36, 36),
          position: Vector2(
            size.x / 2 - 18,
            -40,
          ), // Sits perfectly di atasnya tower (on the roof)
        );
        add(btn);
      } catch (e) {
        debugPrint('Failed to load add icon arena/add_solved.png: $e');
      }
    }
  }

  Future<void> updateAvatar(
    String newName, {
    bool particles = false,
    bool newHasCar = false,
    String newLabel = '',
    bool keepPlus = false,
    bool isAFK = false,
  }) async {
    avatarName = newName;
    if (newLabel.isNotEmpty) label = newLabel;
    this.isAFK = isAFK;

    // Load new avatar sprite concurrently
    if (avatarName.isNotEmpty) {
      final avatarIndex = (newName.hashCode.abs() % 4) + 1;
      Sprite.load('arena/user_$avatarIndex.png')
          .then((sprite) {
            _avatarSprite = sprite;
          })
          .catchError((e) {
            debugPrint('Failed to load avatar arena/user_$avatarIndex.png: $e');
          });
    }

    // Load car Lottie concurrently
    if (newHasCar && _carComponent == null) {
      hasCar = true;
      loadLottie(Lottie.asset('assets/images/arena/car_solved.json'))
          .then((comp) {
            if (!hasCar) return; // Safety check in case it was cleared
            _carComponent = LottieComponent(comp, repeating: true)
              ..size = Vector2(100, 100);
            _carComponent!.position = Vector2(size.x / 2 - 50, -60);
            add(_carComponent!);
          })
          .catchError((e) {
            debugPrint('Car Lottie error: $e');
          });
    }

    // Load typing Lottie concurrently so there's no delay
    if (particles && _particlesComponent == null) {
      hasParticles = true;
      loadLottie(Lottie.asset('assets/images/arena/typing.json'))
          .then((comp) {
            if (!hasParticles)
              return; // Safety check in case the user clicked 'back' quickly
            _particlesComponent = LottieComponent(comp, repeating: true)
              ..size = Vector2(100, 100);
            _particlesComponent!.position = Vector2(size.x / 2 - 50, -60);
            add(_particlesComponent!);
          })
          .catchError((e) {
            debugPrint('Typing Lottie error: $e');
          });
    }

    // Only remove Plus button if explicitly told to (background towers without keepPlus)
    if (isPlus && avatarName.isNotEmpty && !keepPlus) {
      removePlus();
    }
  }

  void removePlus() {
    isPlus = false;
    final btn = children.whereType<BounceSpriteButton>().firstOrNull;
    if (btn != null) {
      btn.removeFromParent();
    }
  }

  void clearContent() {
    avatarName = '';
    hasParticles = false;
    hasCar = false;
    isAFK = false;
    _avatarSprite = null;

    // Remove and null all Lottie components so guards reset correctly
    _particlesComponent?.removeFromParent();
    _particlesComponent = null;
    _carComponent?.removeFromParent();
    _carComponent = null;

    // Safety: remove any stray Lottie children
    final extra = children.whereType<LottieComponent>().toList();
    for (final l in extra) {
      l.removeFromParent();
    }
  }

  double? _baseHeight;

  @override
  void render(Canvas canvas) {
    _baseHeight ??= size.y; // Capture the initial height of the tower

    // Draw standard purple base tower WITHOUT radius
    final rPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), rPaint);

    if (topColor != null) {
      final topPaint = Paint()
        ..color = topColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 15), topPaint);
    } // 2. Draw Top sections (Teal, Olive)
    if (topColor != null || topColor2 != null) {
      if (topColor != null && topColor2 != null) {
        // Split top half again or just stack them?
        // Based on image: top is teal, then olive, then purple.
        // Let's make teal top 30%, olive next 40%, then purple base.
        final tealPaint = Paint()..color = topColor!;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y * 0.25), tealPaint);

        final olivePaint = Paint()..color = topColor2!;
        canvas.drawRect(
          Rect.fromLTWH(0, size.y * 0.25, size.x, size.y * 0.5),
          olivePaint,
        );
      } else if (topColor != null) {
        // Just one top color (Teal) taking up 70% of the bar
        final tPaint = Paint()..color = topColor!;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y * 0.7), tPaint);
      }

      // Gray separating line
      final linePaint = Paint()..color = Colors.grey;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 4), linePaint);
    }

    // 3. Draw avatars at the bottom
    if (avatarName.isNotEmpty) {
      final avatarBg = Rect.fromLTWH(size.x / 2 - 18, size.y - 21, 36, 36);
      final paintBg = Paint()
        ..color = const Color(0xFF6DE0B2); // Cyan background

      canvas.drawRRect(
        RRect.fromRectAndRadius(avatarBg, const Radius.circular(8)),
        paintBg,
      );

      // Render avatar sprite if loaded, else fallback to mock dog icon
      if (_avatarSprite != null) {
        _avatarSprite!.render(
          canvas,
          size: Vector2(28, 28),
          position: Vector2(size.x / 2 - 14, size.y - 17),
        );
      } else {
        final dogPaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(size.x / 2, size.y - 3), 10, dogPaint);
        final earPaint = Paint()..color = Colors.brown;
        canvas.drawCircle(Offset(size.x / 2 - 7, size.y - 7), 4, earPaint);
        canvas.drawCircle(Offset(size.x / 2 + 7, size.y - 7), 4, earPaint);
      }

      // Draw AFK indicator dot on top-right of avatar if AFK
      if (isAFK) {
        final afkDotPaint = Paint()..color = Colors.red;
        final afkBorderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        // Positioned slightly right and up relative to the center
        final dotPos = Offset(size.x / 2 + 12, size.y - 17);
        canvas.drawCircle(dotPos, 5, afkDotPaint);
        canvas.drawCircle(dotPos, 5, afkBorderPaint);
      }

      // Label
      final span = TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        text: avatarName,
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(size.x / 2 - tp.width / 2, size.y + 18));
    }

    // 4. Draw label for base tower (1000)
    if (label.isNotEmpty) {
      final span = TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        text: label,
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, const Offset(10, 10));
    }

    // 5. Removed static car rendering as we now use LottieComponent
    // Fallback if Lottie is broken or has startFrame == endFrame
    if (hasCar && _lottieFailed) {
      final carPaint = Paint()..color = const Color(0xFFE54D4D);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.x / 2 - 18, -25, 36, 16),
          const Radius.circular(4),
        ),
        carPaint,
      );

      final glassPaint = Paint()..color = Colors.blue.withOpacity(0.5);
      canvas.drawRect(Rect.fromLTWH(size.x / 2 - 10, -25, 12, 6), glassPaint);

      final wheelPaint = Paint()..color = Colors.white;
      final tirePaint = Paint()..color = Colors.black;
      canvas.drawCircle(Offset(size.x / 2 - 10, -9), 5, tirePaint);
      canvas.drawCircle(Offset(size.x / 2 - 10, -9), 2, wheelPaint);
      canvas.drawCircle(Offset(size.x / 2 + 10, -9), 5, tirePaint);
      canvas.drawCircle(Offset(size.x / 2 + 10, -9), 2, wheelPaint);
    }
  }
}
