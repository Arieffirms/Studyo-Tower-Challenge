import '../../domain/entities/player_entity.dart';

class PlayerModel extends PlayerEntity {
  const PlayerModel({
    required super.playerId,
    required super.displayName,
    required super.team,
    super.isBot,
  });

  factory PlayerModel.fromJson(Map<dynamic, dynamic> json, String id) {
    return PlayerModel(
      playerId: id,
      displayName: json['displayName'] ?? 'Unknown',
      team: json['team'] ?? '',
      isBot: json['isBot'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'team': team,
      'isBot': isBot,
    };
  }

  factory PlayerModel.fromEntity(PlayerEntity entity) {
    return PlayerModel(
      playerId: entity.playerId,
      displayName: entity.displayName,
      team: entity.team,
      isBot: entity.isBot,
    );
  }
}
