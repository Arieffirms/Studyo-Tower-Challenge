import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/arena_player_model.dart';

/// Abstract contract for all Firebase operations related to the Tower Challenge.
abstract class TowerChallengeRemoteDataSource {
  /// Streams all players in a match (returns parsed [ArenaPlayerModel] list on each change).
  Stream<Map<String, ArenaPlayerModel>> observePlayers(String matchId);

  /// Sends a heartbeat (lastSeenAt) for the human player.
  Future<void> updateHeartbeat(String matchId, String uid);

  /// Reads match meta (status, startAt, durationSec) once.
  Future<Map<String, dynamic>?> fetchMatchMeta(String matchId);

  /// Claims a tower for a player. Returns true if the write succeeds.
  Future<bool> claimTower({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
  });

  /// Marks a tower as solved and updates the player's stats.
  Future<void> solveTower({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
    required int movesTaken,
  });

  /// Releases a claimed tower (player backed out / went AFK).
  Future<void> releaseTower({
    required String matchId,
    required String teamId,
    required String towerId,
  });

  /// Simulates a bot's stats update (towersSolved, totalMoves, averageMoves).
  Future<void> simulateBotMove({
    required String matchId,
    required String botId,
    required int movesToAdd,
  });

  /// Assigns a team to the current player and balances bot team assignments.
  Future<void> assignTeamAndBalanceBots(String matchId, String uid, String team);

  /// Updates the total team scores in Firebase.
  Future<void> updateTeamScores(String matchId, int scoreA, int scoreB);
}

/// Firebase implementation of [TowerChallengeRemoteDataSource].
class TowerChallengeRemoteDataSourceImpl
    implements TowerChallengeRemoteDataSource {
  final FirebaseDatabase _db;

  TowerChallengeRemoteDataSourceImpl({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  DatabaseReference _matchRef(String matchId) =>
      _db.ref('liveMatches/$matchId');

  @override
  Stream<Map<String, ArenaPlayerModel>> observePlayers(String matchId) {
    return _matchRef(matchId).child('players').onValue.map((event) {
      if (!event.snapshot.exists) return {};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final result = <String, ArenaPlayerModel>{};
      data.forEach((key, val) {
        try {
          result[key] =
              ArenaPlayerModel.fromJson(key, val as Map<dynamic, dynamic>);
        } catch (e) {
          debugPrint('Error parsing player $key: $e');
        }
      });
      return result;
    });
  }

  @override
  Future<void> updateHeartbeat(String matchId, String uid) async {
    try {
      await _matchRef(matchId)
          .child('players/$uid')
          .update({'lastSeenAt': DateTime.now().millisecondsSinceEpoch});
    } catch (e) {
      debugPrint('Heartbeat failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchMatchMeta(String matchId) async {
    try {
      final snap = await _matchRef(matchId).child('meta').get();
      if (!snap.exists) return null;
      return Map<String, dynamic>.from(snap.value as Map);
    } catch (e) {
      debugPrint('fetchMatchMeta failed: $e');
      return null;
    }
  }

  @override
  Future<bool> claimTower({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
  }) async {
    // Local processing only (user explicitly requested removing teams/towers logic)
    return true;
  }

  @override
  Future<void> solveTower({
    required String matchId,
    required String teamId,
    required String towerId,
    required String playerId,
    required int movesTaken,
  }) async {
    try {
      final statsRef =
          _matchRef(matchId).child('players/$playerId/stats');
      final snap = await statsRef.get();
      int currentMoves = 0;
      int currentTowers = 0;
      if (snap.exists) {
        final s = Map<String, dynamic>.from(snap.value as Map);
        currentMoves = s['totalMoves'] ?? 0;
        currentTowers = s['towersSolved'] ?? 0;
      }
      final newTowers = currentTowers + 1;
      final newTotalMoves = currentMoves + movesTaken;
      await statsRef.update({
        'towersSolved': newTowers,
        'totalMoves': newTotalMoves,
        'averageMoves': newTotalMoves ~/ newTowers,
      });
    } catch (e) {
      debugPrint('solveTower RTDB update failed: $e');
    }
  }

  @override
  Future<void> releaseTower({
    required String matchId,
    required String teamId,
    required String towerId,
  }) async {
    // Local processing only
  }

  @override
  Future<void> simulateBotMove({
    required String matchId,
    required String botId,
    required int movesToAdd,
  }) async {
    try {
      final ref = _matchRef(matchId).child('players/$botId');
      final snap = await ref.child('stats').get();
      int tMoves = 0;
      int currentSolved = 0;
      if (snap.exists) {
        final s = Map<String, dynamic>.from(snap.value as Map);
        tMoves = s['totalMoves'] ?? 0;
        currentSolved = s['towersSolved'] ?? 0;
      }
      final newSolved = currentSolved + 1;
      final newMoves = tMoves + movesToAdd;
      await ref.update({
        'lastSeenAt': DateTime.now().millisecondsSinceEpoch,
        'stats/towersSolved': newSolved,
        'stats/totalMoves': newMoves,
        'stats/averageMoves': (newMoves / newSolved).round(),
      });
    } catch (e) {
      debugPrint('simulateBotMove failed: $e');
    }
  }

  @override
  Future<void> assignTeamAndBalanceBots(String matchId, String uid, String team) async {
    try {
      await _matchRef(matchId).child('players/$uid').update({'team': team});

      // Balance the bots
      final playersSnap = await _matchRef(matchId).child('players').get();
      if (playersSnap.exists) {
        final playersData = Map<String, dynamic>.from(playersSnap.value as Map);
        String nextTeamToAssign = team == 'A' ? 'B' : 'A';
        final updates = <String, dynamic>{};
        for (final entry in playersData.entries) {
          final p = entry.value as Map;
          if (p['isBot'] == true && (p['team'] == null || p['team'] == '')) {
            updates['${entry.key}/team'] = nextTeamToAssign;
            nextTeamToAssign = nextTeamToAssign == 'A' ? 'B' : 'A';
          }
        }
        if (updates.isNotEmpty) {
          await _matchRef(matchId).child('players').update(updates);
        }
      }
    } catch (e) {
      debugPrint('Failed to assign team in RTDB: $e');
    }
  }

  @override
  Future<void> updateTeamScores(String matchId, int scoreA, int scoreB) async {
    try {
      await _matchRef(matchId).child('teams').update({
        'A/score': scoreA,
        'B/score': scoreB,
      });
    } catch (e) {
      debugPrint('updateTeamScores failed: $e');
    }
  }
}
