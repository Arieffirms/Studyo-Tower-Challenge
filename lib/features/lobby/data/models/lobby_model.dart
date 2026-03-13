import '../../domain/entities/lobby_entity.dart';

class LobbyModel extends LobbyEntity {
  const LobbyModel({
    required super.lobbyId,
    required super.status,
    required super.createdAt,
    super.matchStartTime,
    super.durationSec,
    super.playerIds,
  });

  factory LobbyModel.fromJson(Map<dynamic, dynamic> json, String id) {
    List<String> players = [];
    if (json['players'] != null) {
      final playersMap = json['players'] as Map<dynamic, dynamic>;
      players = playersMap.keys.cast<String>().toList();
    }

    final meta = json['meta'] as Map<dynamic, dynamic>? ?? {};

    return LobbyModel(
      lobbyId: id,
      status: meta['status'] ?? 'lobby',
      createdAt: meta['startAt'] ?? 0,
      matchStartTime: meta['startAt'],
      durationSec: meta['durationSec'] ?? 300,
      playerIds: players,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meta': {
        'status': status,
        'startAt': createdAt,
        'durationSec': durationSec,
      }
      // teams and players will be handled separately in Firebase to avoid overwriting
    };
  }
}
