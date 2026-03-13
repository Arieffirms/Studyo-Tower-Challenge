import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/lobby_model.dart';
import '../models/player_model.dart';

abstract class LobbyRemoteDataSource {
  Future<String> joinOnlineLobby(PlayerModel player);
  Future<String> createVsComputerLobby(PlayerModel player);
  Stream<LobbyModel> observeLobby(String lobbyId);
  Future<void> fillWithBots(String lobbyId, int botsToAdd);
  Future<void> leaveLobby(String lobbyId, String playerId);
}

class LobbyRemoteDataSourceImpl implements LobbyRemoteDataSource {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Membantu membuat initial state untuk Tim
  Map<String, dynamic> _createInitialTeamData() {
    return {
      'targetValue': 1000,
      'opAdd': 10,
      'opMul': 2,
      'score': 0,
      'towers': {}, // Akan diisi Game Logic nanti
    };
  }

  @override
  Future<String> joinOnlineLobby(PlayerModel player) async {
    // 1. Cari liveMatch yang berstatus 'lobby' (waiting room)
    final query = _db
        .ref('liveMatches')
        .orderByChild('meta/status')
        .equalTo('lobby')
        .limitToFirst(1);
    final snapshot = await query.get();

    String matchId;

    if (snapshot.exists) {
      // 2a. Join match yang sudah ada
      final map = snapshot.value as Map<dynamic, dynamic>;
      matchId = map.keys.first.toString();

      final matchRef = _db.ref('liveMatches/$matchId');

      // Update player ke tim yang kosong atau random
      await matchRef.child('players/${player.playerId}').set(player.toJson());

      // Cek apakah sudah penuh
      final matchSnap = await matchRef.get();
      if (matchSnap.exists) {
        final matchMap = matchSnap.value as Map<dynamic, dynamic>;
        final playersMap = matchMap['players'] as Map<dynamic, dynamic>? ?? {};
        if (playersMap.length >= 8) {
          await matchRef.child('meta').update({
            'status': 'starting', // Segera berubah jadi running
            'startAt': ServerValue.timestamp,
            'durationSec': 300,
          });
        }
      }
    } else {
      // 2b. Buat match baru
      final newMatchRef = _db.ref('liveMatches').push();
      matchId = newMatchRef.key!;

      final newMatchData = {
        'meta': {
          'status': 'lobby',
          'startAt': ServerValue.timestamp,
          'durationSec': 300,
        },
        'teams': {
          'A': _createInitialTeamData(),
          'B': _createInitialTeamData(),
        },
      };

      await newMatchRef.set(newMatchData);
      await newMatchRef
          .child('players/${player.playerId}')
          .set(player.toJson());
    }

    return matchId;
  }

  @override
  Future<String> createVsComputerLobby(PlayerModel player) async {
    final newMatchRef = _db.ref('liveMatches').push();
    final matchId = newMatchRef.key!;

    final newMatchData = {
      'meta': {
        'status': 'starting', // Langsung starting
        'startAt': ServerValue.timestamp,
        'durationSec': 300,
      },
      'teams': {
        'A': _createInitialTeamData(),
        'B': _createInitialTeamData(),
      },
    };

    await newMatchRef.set(newMatchData);

    // Masukkan player manusia (tim dan statusnya)
    await newMatchRef.child('players/${player.playerId}').set(player.toJson());

    // Isi 7 slot lainnya dengan Bot
    await fillWithBots(matchId, 7);

    return matchId;
  }

  @override
  Stream<LobbyModel> observeLobby(String lobbyId) {
    return _db.ref('liveMatches/$lobbyId').onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return LobbyModel.fromJson(data, event.snapshot.key!);
      }
      throw Exception('Match not found');
    });
  }

  @override
  Future<void> fillWithBots(String lobbyId, int botsToAdd) async {
    final playersRef = _db.ref('liveMatches/$lobbyId/players');

    // Fake names written to Firebase so displayName is correct everywhere
    const fakeBotNames = [
      'Arif', 'Zela', 'Riko', 'Dimas', 'Lina',
      'Fajar', 'Sinta', 'Niko', 'Dewi', 'Hendra',
      'Putri', 'Andi', 'Rina', 'Bayu', 'Citra',
    ];

    final updates = <String, dynamic>{};
    for (int i = 0; i < botsToAdd; i++) {
      final botId = 'bot_${DateTime.now().millisecondsSinceEpoch}_$i';
      final bot = PlayerModel(
        playerId: botId,
        displayName: fakeBotNames[i % fakeBotNames.length],
        team: '',
        isBot: true,
        isAFK: false,
        lastSeenAt: DateTime.now().millisecondsSinceEpoch,
      );
      updates[botId] = bot.toJson();
    }

    await playersRef.update(updates);

    // Ubah status jika belum 'starting'
    await _db.ref('liveMatches/$lobbyId/meta').update({
      'status': 'starting',
      'startAt': ServerValue.timestamp,
    });
  }

  @override
  Future<void> leaveLobby(String lobbyId, String playerId) async {
    await _db.ref('liveMatches/$lobbyId/players/$playerId').remove();

    // Hapus lobby jika sudah tidak ada player
    final snapshot = await _db.ref('liveMatches/$lobbyId/players').get();
    if (!snapshot.exists) {
      await _db.ref('liveMatches/$lobbyId').remove();
    }
  }
}
