import 'package:equatable/equatable.dart';

/// Represents the current user of the app.
/// Since there's no login, this holds the randomly generated playerId.
class AppUserEntity extends Equatable {
  final String playerId;
  final String displayName; // Can be Auto-generated or custom

  const AppUserEntity({required this.playerId, required this.displayName});

  @override
  List<Object?> get props => [playerId, displayName];
}
