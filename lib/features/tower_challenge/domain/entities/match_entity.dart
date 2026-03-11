import 'package:equatable/equatable.dart';
import 'team_entity.dart';

class MatchEntity extends Equatable {
  final String matchId; // Same as lobbyId
  final String status; // 'running', 'ended'
  final int startAt;
  final int endAt; // Usually startAt + 5 minutes
  final TeamEntity teamA;
  final TeamEntity teamB;

  const MatchEntity({
    required this.matchId,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.teamA,
    required this.teamB,
  });

  bool get isRunning => status == 'running';
  bool get isEnded => status == 'ended';

  @override
  List<Object?> get props => [matchId, status, startAt, endAt, teamA, teamB];
}
