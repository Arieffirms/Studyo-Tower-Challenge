import 'package:equatable/equatable.dart';

/// Represents a Player in the game lobby and during the match.
class PlayerEntity extends Equatable {
  final String playerId;
  final String displayName;
  final String team; // e.g., 'A', 'B', or empty if unassigned
  final bool isBot;

  const PlayerEntity({
    required this.playerId,
    required this.displayName,
    required this.team,
    this.isBot = false,
  });

  @override
  List<Object?> get props => [playerId, displayName, team, isBot];
}
