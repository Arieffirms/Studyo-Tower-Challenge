import 'package:equatable/equatable.dart';

/// Represents a matchmaking session (Lobby) waiting for players.
class LobbyEntity extends Equatable {
  final String lobbyId;
  final String status; // 'waiting', 'starting'
  final int createdAt; // Timestamp when lobby was created
  final int? matchStartTime; // Timestamp when 'starting' phase finishes
  final List<String> playerIds; // List of joined Player IDs (human or bot)

  const LobbyEntity({
    required this.lobbyId,
    required this.status,
    required this.createdAt,
    this.matchStartTime,
    this.playerIds = const [],
  });

  /// Check if the lobby is full (max 8 players)
  bool get isFull => playerIds.length >= 8;

  /// Check if the 2-minute waiting period has passed
  bool isWaitTimeExpired(int currentTimeMs) {
    return (currentTimeMs - createdAt) >= 120000; // 2 minutes in ms
  }

  @override
  List<Object?> get props => [lobbyId, status, createdAt, matchStartTime, playerIds];
}
