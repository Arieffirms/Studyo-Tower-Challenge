import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Reusable Image Button dengan effect scale
// (pengganti SimpleImageButton dari Flame)
// ─────────────────────────────────────────────
class SimpleImageButton extends StatefulWidget {
  final String assetPath;
  final VoidCallback onClick;
  final double width;
  final double height;

  const SimpleImageButton({
    super.key,
    required this.assetPath,
    required this.onClick,
    this.width = 180,
    this.height = 55,
  });

  @override
  State<SimpleImageButton> createState() => _SimpleImageButtonState();
}

class _SimpleImageButtonState extends State<SimpleImageButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut, // bounce saat lepas
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onClick();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Image.asset(
          widget.assetPath,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
