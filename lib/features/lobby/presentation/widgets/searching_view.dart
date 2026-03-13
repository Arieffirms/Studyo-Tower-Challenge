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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF2D1B4E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Searching for match...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Players matched — reaktif via Obx
            Obx(() {
              final count = controller.activeLobby.value?.playerIds.length ?? 
                            controller.vsComputerSimulatedCount.value;
              return Text(
                "Players matched: $count / 8",
                style: const TextStyle(
                  color: Color(0xFF6DE0B2), 
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),

            const SizedBox(height: 16),

            // Timer — reaktif via Obx
            Obx(() {
              final time = controller.secondsRemaining.value;
              final m = (time ~/ 60);
              final s = time % 60;
              final isOnline = controller.activeLobby.value != null;
              final label = isOnline ? "Time remaining" : "Searching time";
              
              return Text(
                "$label: ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}",
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              );
            }),

            const SizedBox(height: 40),

            // Cancel button
            _CancelButton(onPressed: () => controller.cancelSearch()),
          ],
        ),
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
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(12),
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
