import 'package:flutter/material.dart';

enum PlayerColor { red, green, yellow, blue }

enum PlayerType { human, ai }

enum TurnPhase { rolling, selecting, animating, finished }

extension PlayerColorX on PlayerColor {
  Color get color {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFE53935);
      case PlayerColor.green:
        return const Color(0xFF43A047);
      case PlayerColor.yellow:
        return const Color(0xFFFDD835);
      case PlayerColor.blue:
        return const Color(0xFF1E88E5);
    }
  }

  Color get darkColor {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFB71C1C);
      case PlayerColor.green:
        return const Color(0xFF1B5E20);
      case PlayerColor.yellow:
        return const Color(0xFFF9A825);
      case PlayerColor.blue:
        return const Color(0xFF0D47A1);
    }
  }

  String get label {
    switch (this) {
      case PlayerColor.red:
        return 'Red';
      case PlayerColor.green:
        return 'Green';
      case PlayerColor.yellow:
        return 'Yellow';
      case PlayerColor.blue:
        return 'Blue';
    }
  }

  /// Global board index where this color enters the main track.
  int get startIndex {
    switch (this) {
      case PlayerColor.red:
        return 0;
      case PlayerColor.green:
        return 13;
      case PlayerColor.yellow:
        return 26;
      case PlayerColor.blue:
        return 39;
    }
  }
}

class PlayerConfig {
  final PlayerColor color;
  final PlayerType type;
  final String name;

  const PlayerConfig({
    required this.color,
    required this.type,
    required this.name,
  });
}

/// Token position:
/// -1 = yard (base)
/// 0..50 = main track (relative to player start)
/// 51..55 = home stretch
/// 56 = finished
class Token {
  final int id;
  final PlayerColor color;
  int position;

  Token({required this.id, required this.color, this.position = -1});

  bool get inYard => position < 0;
  bool get finished => position >= 56;
  bool get onHomeStretch => position >= 51 && position < 56;
  bool get onMainTrack => position >= 0 && position <= 50;

  Token copy() => Token(id: id, color: color, position: position);
}

class Player {
  final PlayerColor color;
  final PlayerType type;
  final String name;
  final List<Token> tokens;

  Player({
    required this.color,
    required this.type,
    required this.name,
  }) : tokens = List.generate(
          4,
          (i) => Token(id: i, color: color),
        );

  bool get hasWon => tokens.every((t) => t.finished);

  int get finishedCount => tokens.where((t) => t.finished).length;
}
