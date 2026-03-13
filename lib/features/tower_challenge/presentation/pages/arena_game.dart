import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'arena_board_component.dart';

class ArenaGame extends FlameGame {
  final String? lobbyId;
  final String? uid;
  final void Function(String)? onTeamSelected;

  ArenaGame({this.lobbyId, this.uid, this.onTeamSelected});

  @override
  Color backgroundColor() => Colors.transparent; // Let flutter background show

  @override
  Future<void> onLoad() async {
    add(ArenaBoardComponent(
      lobbyId: lobbyId,
      uid: uid,
      onTeamSelected: onTeamSelected,
    ));
  }
}
