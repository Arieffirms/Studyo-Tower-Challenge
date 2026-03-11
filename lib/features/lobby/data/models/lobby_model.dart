import '../../domain/entities/lobby_entity.dart';

class LobbyModel extends LobbyEntity {
  const LobbyModel({
    required super.lobbyId,
    required super.status,
    required super.createdAt,
    super.matchStartTime,
    super.playerIds,
  });

  factory LobbyModel.fromJson(Map<dynamic, dynamic> json, String id) {
    List<String> players = [];
    if (json['players'] != null) {
      final playersMap = json['players'] as Map<dynamic, dynamic>;
      players = playersMap.keys.cast<String>().toList();
    }

    return LobbyModel(
      lobbyId: id,
      status: json['status'] ?? 'waiting',
      createdAt: json['createdAt'] ?? 0,
      matchStartTime: json['matchStartTime'],
      playerIds: players,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'createdAt': createdAt,
      'matchStartTime': matchStartTime,
      // players will be handled separately in Firebase to avoid overwriting
    };
  }
}
