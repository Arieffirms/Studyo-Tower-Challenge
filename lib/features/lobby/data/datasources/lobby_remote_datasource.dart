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

  @override
  Future<String> joinOnlineLobby(PlayerModel player) async {
    // 1. Find a waiting lobby
    final query = _db
        .ref('lobbies')
        .orderByChild('status')
        .equalTo('waiting')
        .limitToFirst(1);
    final snapshot = await query.get();

    String lobbyId;

    if (snapshot.exists) {
      // 2a. Join existing lobby
      final map = snapshot.value as Map<dynamic, dynamic>;
      lobbyId = map.keys.first.toString();

      // We must use transaction here to avoid race conditions when joining
      final lobbyRef = _db.ref('lobbies/$lobbyId');

      // Update player
      await lobbyRef.child('players/${player.playerId}').set(player.toJson());

      // Check if full (this should ideally be a cloud function, doing it client side for simplicity)
      final lobbySnap = await lobbyRef.get();
      if (lobbySnap.exists) {
        final lobbyMap = lobbySnap.value as Map<dynamic, dynamic>;
        final playersMap = lobbyMap['players'] as Map<dynamic, dynamic>? ?? {};
        if (playersMap.length >= 8) {
          await lobbyRef.update({
            'status': 'starting',
            'matchStartTime': ServerValue.timestamp,
          });
        }
      }
    } else {
      // 2b. Create new lobby
      final newLobbyRef = _db.ref('lobbies').push();
      lobbyId = newLobbyRef.key!;

      final newLobby = {
        'status': 'waiting',
        'createdAt': ServerValue.timestamp,
      };

      await newLobbyRef.set(newLobby);
      await newLobbyRef
          .child('players/${player.playerId}')
          .set(player.toJson());
    }

    return lobbyId;
  }

  @override
  Future<String> createVsComputerLobby(PlayerModel player) async {
    final newLobbyRef = _db.ref('lobbies').push();
    final lobbyId = newLobbyRef.key!;

    final newLobby = {
      'status': 'starting', // skips 'waiting' phase
      'createdAt': ServerValue.timestamp,
      'matchStartTime': ServerValue.timestamp,
    };

    await newLobbyRef.set(newLobby);

    // add human player
    await newLobbyRef.child('players/${player.playerId}').set(player.toJson());

    // fill 7 bots
    await fillWithBots(lobbyId, 7);

    return lobbyId;
  }

  @override
  Stream<LobbyModel> observeLobby(String lobbyId) {
    return _db.ref('lobbies/$lobbyId').onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return LobbyModel.fromJson(data, event.snapshot.key!);
      }
      throw Exception('Lobby not found');
    });
  }

  @override
  Future<void> fillWithBots(String lobbyId, int botsToAdd) async {
    final playersRef = _db.ref('lobbies/$lobbyId/players');

    final updates = <String, dynamic>{};
    for (int i = 0; i < botsToAdd; i++) {
      final botId = 'bot_${DateTime.now().millisecondsSinceEpoch}_$i';
      final bot = PlayerModel(
        playerId: botId,
        displayName: 'AI Bot \${i+1}',
        team: i % 2 == 0 ? 'A' : 'B', // Will balance later, naive assign here
        isBot: true,
      );
      updates[botId] = bot.toJson();
    }

    await playersRef.update(updates);

    // Also change status if full
    await _db.ref('lobbies/$lobbyId').update({
      'status': 'starting',
      'matchStartTime': ServerValue.timestamp,
    });
  }

  @override
  Future<void> leaveLobby(String lobbyId, String playerId) async {
    await _db.ref('lobbies/$lobbyId/players/$playerId').remove();

    // If lobby is empty after leaving, can optionally delete it
    final snapshot = await _db.ref('lobbies/$lobbyId/players').get();
    if (!snapshot.exists) {
      await _db.ref('lobbies/$lobbyId').remove();
    }
  }
}
