import 'package:equatable/equatable.dart';

class PlayerStatsEntity extends Equatable {
  final int towersSolved;
  final int totalMoves;
  final int averageMoves;
  final int afkTimeSeconds;

  const PlayerStatsEntity({
    this.towersSolved = 0,
    this.totalMoves = 0,
    this.averageMoves = 0,
    this.afkTimeSeconds = 0,
  });

  @override
  List<Object?> get props => [towersSolved, totalMoves, averageMoves, afkTimeSeconds];
}

/// Represents a Player in the game lobby and during the match.
class PlayerEntity extends Equatable {
  final String playerId;
  final String displayName;
  final String team; // e.g., 'A', 'B', or empty if unassigned
  final bool isBot;
  final int? lastSeenAt;
  final bool isAFK;
  final PlayerStatsEntity stats;

  const PlayerEntity({
    required this.playerId,
    required this.displayName,
    required this.team,
    this.isBot = false,
    this.lastSeenAt,
    this.isAFK = false,
    this.stats = const PlayerStatsEntity(),
  });

  @override
  List<Object?> get props => [playerId, displayName, team, isBot, lastSeenAt, isAFK, stats];
}
