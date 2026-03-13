/// Arena-specific player model used by ArenaBoardComponent and ArenaController.
/// Converts raw Firebase player snapshots into a domain-friendly [ArenaPlayerModel].
class ArenaPlayerModel {
  final String id;
  final String name;
  final int score;
  final bool isBot;
  final String? team;
  final bool isAFK;

  const ArenaPlayerModel({
    required this.id,
    required this.name,
    required this.score,
    required this.isBot,
    this.team,
    this.isAFK = false,
  });

  factory ArenaPlayerModel.fromJson(String id, Map<dynamic, dynamic> json) {
    final isBot = json['isBot'] == true;
    final stats = json['stats'] != null
        ? Map<String, dynamic>.from(json['stats'] as Map)
        : null;
    final team = stats?['team'] ?? json['team'];

    // Score: compute from existing stats — 200/averageMoves per tower solved
    final int towersSolved = stats?['towersSolved'] ?? 0;
    final int avgMoves = (stats?['averageMoves'] as num?)?.round() ?? 0;
    final int scorePerTower = avgMoves > 0
        ? (200 / avgMoves).floor().clamp(1, 200)
        : (towersSolved > 0 ? 10 : 0); // fallback if no move data yet
    final int score = scorePerTower * towersSolved;

    // AFK: if lastSeenAt is older than 30s (only for humans)
    bool isPlayerAFK = false;
    final lastSeen = json['lastSeenAt'] as int?;
    if (lastSeen != null && !isBot) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastSeen > 30000) isPlayerAFK = true;
    }

    return ArenaPlayerModel(
      id: id,
      name: json['displayName'] ?? 'Unknown',
      score: score,
      isBot: isBot,
      team: team as String?,
      isAFK: isPlayerAFK,
    );
  }

  ArenaPlayerModel copyWith({
    String? id,
    String? name,
    int? score,
    bool? isBot,
    String? team,
    bool? isAFK,
  }) {
    return ArenaPlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      isBot: isBot ?? this.isBot,
      team: team ?? this.team,
      isAFK: isAFK ?? this.isAFK,
    );
  }
}
