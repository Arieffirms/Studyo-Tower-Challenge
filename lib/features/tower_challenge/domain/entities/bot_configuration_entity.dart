import 'package:equatable/equatable.dart';

/// Configuration for an AI Bot in the game.
class BotConfigurationEntity extends Equatable {
  final String botId; // e.g., 'bot_1', 'bot_2'
  final String team; // 'A' or 'B'
  final double skillLevel; // 0.0 (Random) to 1.0 (Optimal)
  final int delayMs; // Delay between moves to simulate human behavior

  const BotConfigurationEntity({
    required this.botId,
    required this.team,
    this.skillLevel = 0.8,
    this.delayMs = 2000,
  });

  @override
  List<Object?> get props => [botId, team, skillLevel, delayMs];
}
