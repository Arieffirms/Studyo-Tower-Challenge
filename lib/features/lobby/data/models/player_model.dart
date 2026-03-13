import '../../domain/entities/player_entity.dart';

class PlayerStatsModel extends PlayerStatsEntity {
  const PlayerStatsModel({
    super.towersSolved = 0,
    super.totalMoves = 0,
    super.averageMoves = 0,
    super.afkTimeSeconds = 0,
  });

  factory PlayerStatsModel.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return const PlayerStatsModel();
    return PlayerStatsModel(
      towersSolved: json['towersSolved'] ?? 0,
      totalMoves: json['totalMoves'] ?? 0,
      averageMoves: json['averageMoves'] ?? 0,
      afkTimeSeconds: json['afkTimeSeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'towersSolved': towersSolved,
      'totalMoves': totalMoves,
      'averageMoves': averageMoves,
      'afkTimeSeconds': afkTimeSeconds,
    };
  }
}

class PlayerModel extends PlayerEntity {
  const PlayerModel({
    required super.playerId,
    required super.displayName,
    required super.team,
    super.isBot,
    super.lastSeenAt,
    super.isAFK,
    super.stats,
  });

  factory PlayerModel.fromJson(Map<dynamic, dynamic> json, String id) {
    return PlayerModel(
      playerId: id,
      displayName: json['displayName'] ?? 'Unknown',
      team: json['team'] ?? '',
      isBot: json['isBot'] ?? false,
      lastSeenAt: json['lastSeenAt'],
      isAFK: json['isAFK'] ?? false,
      stats: PlayerStatsModel.fromJson(json['stats'] as Map<dynamic, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'displayName': displayName,
      'team': team,
      'isBot': isBot,
      'isAFK': isAFK,
    };
    if (lastSeenAt != null) {
      map['lastSeenAt'] = lastSeenAt;
    }
    if (stats is PlayerStatsModel) {
      map['stats'] = (stats as PlayerStatsModel).toJson();
    } else {
      map['stats'] = PlayerStatsModel(
        towersSolved: stats.towersSolved,
        totalMoves: stats.totalMoves,
        averageMoves: stats.averageMoves,
        afkTimeSeconds: stats.afkTimeSeconds,
      ).toJson();
    }
    return map;
  }

  factory PlayerModel.fromEntity(PlayerEntity entity) {
    return PlayerModel(
      playerId: entity.playerId,
      displayName: entity.displayName,
      team: entity.team,
      isBot: entity.isBot,
      lastSeenAt: entity.lastSeenAt,
      isAFK: entity.isAFK,
      stats: entity.stats,
    );
  }
}
