import 'package:equatable/equatable.dart';
import '../../../../features/lobby/domain/entities/player_entity.dart';
import 'tower_entity.dart';

class TeamEntity extends Equatable {
  final String teamId; // 'A' or 'B'
  final int targetValue;
  final int score;
  final Map<String, TowerEntity> towers; // 20 active towers
  final List<PlayerEntity> members;

  const TeamEntity({
    required this.teamId,
    required this.targetValue,
    required this.score,
    required this.towers,
    required this.members,
  });

  @override
  List<Object?> get props => [teamId, targetValue, score, towers, members];
}
