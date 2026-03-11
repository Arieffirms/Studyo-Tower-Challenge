import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/lobby_controller.dart';

// ─────────────────────────────────────────────
// Searching Screen
// ─────────────────────────────────────────────
class SearchingView extends GetView<LobbyController> {
  const SearchingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Searching for match...',
            style: TextStyle(
              color: Color(0xFF2D1B4E),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Players matched — reaktif via Obx
          Obx(() {
            final count = controller.activeLobby.value?.playerIds.length ?? 1;
            return Text(
              'Players matched: \$count / 8',
              style: const TextStyle(color: Color(0xFF6B21A8), fontSize: 20),
            );
          }),

          const SizedBox(height: 16),

          // Timer — reaktif via Obx
          Obx(() {
            final time = controller.secondsRemaining.value;
            final m = (time / 60).floor();
            final s = time % 60;
            return Text(
              "Time remaining: \${m.toString().padLeft(2, '0')}:\${s.toString().padLeft(2, '0')}",
              style: const TextStyle(color: Color(0xFF4A1A6E), fontSize: 18),
            );
          }),

          const SizedBox(height: 40),

          // Cancel button
          _CancelButton(onPressed: () => controller.isSearching.value = false),
        ],
      ),
    );
  }
}

// Cancel button dengan effect scale
class _CancelButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _CancelButton({required this.onPressed});

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton>
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 250,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Cancel Request',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
