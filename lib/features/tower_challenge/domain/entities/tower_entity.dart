import 'package:equatable/equatable.dart';

class TowerEntity extends Equatable {
  final String id;
  final int startValue;
  final int currentValue;
  final String state; // 'available', 'claimed', 'solved'
  final String? claimedBy; // playerId who claimed it
  final int? claimExpiresAt; // timestamp
  final String? solvedBy; // playerId who solved it
  final int? solvedAt; // timestamp
  final int movesTaken;
  final int optimalMoves; // min moves required

  const TowerEntity({
    required this.id,
    required this.startValue,
    required this.currentValue,
    required this.state,
    this.claimedBy,
    this.claimExpiresAt,
    this.solvedBy,
    this.solvedAt,
    this.movesTaken = 0,
    this.optimalMoves = 0,
  });

  bool get isAvailable => state == 'available';
  bool get isClaimed => state == 'claimed';
  bool get isSolved => state == 'solved';

  @override
  List<Object?> get props => [
        id,
        startValue,
        currentValue,
        state,
        claimedBy,
        claimExpiresAt,
        solvedBy,
        solvedAt,
        movesTaken,
        optimalMoves,
      ];
}
