import 'dart:ui';

import 'models.dart';

/// Classic 15×15 Ludo layout. Coordinates are (column, row) in 0..14.
class BoardGeometry {
  BoardGeometry._();

  static const int size = 15;

  /// 52 main-track cells clockwise from Red's entry.
  static const List<Offset> mainPath = [
    Offset(6, 13), Offset(6, 12), Offset(6, 11), Offset(6, 10), Offset(6, 9),
    Offset(5, 8), Offset(4, 8), Offset(3, 8), Offset(2, 8), Offset(1, 8), Offset(0, 8),
    Offset(0, 7), Offset(0, 6),
    Offset(1, 6), Offset(2, 6), Offset(3, 6), Offset(4, 6), Offset(5, 6),
    Offset(6, 5), Offset(6, 4), Offset(6, 3), Offset(6, 2), Offset(6, 1), Offset(6, 0),
    Offset(7, 0), Offset(8, 0),
    Offset(8, 1), Offset(8, 2), Offset(8, 3), Offset(8, 4), Offset(8, 5),
    Offset(9, 6), Offset(10, 6), Offset(11, 6), Offset(12, 6), Offset(13, 6), Offset(14, 6),
    Offset(14, 7), Offset(14, 8),
    Offset(13, 8), Offset(12, 8), Offset(11, 8), Offset(10, 8), Offset(9, 8),
    Offset(8, 9), Offset(8, 10), Offset(8, 11), Offset(8, 12), Offset(8, 13), Offset(8, 14),
    Offset(7, 14), Offset(6, 14),
  ];

  static const Map<PlayerColor, List<Offset>> homeStretch = {
    PlayerColor.red: [
      Offset(7, 13), Offset(7, 12), Offset(7, 11), Offset(7, 10), Offset(7, 9),
    ],
    PlayerColor.green: [
      Offset(1, 7), Offset(2, 7), Offset(3, 7), Offset(4, 7), Offset(5, 7),
    ],
    PlayerColor.yellow: [
      Offset(7, 1), Offset(7, 2), Offset(7, 3), Offset(7, 4), Offset(7, 5),
    ],
    PlayerColor.blue: [
      Offset(13, 7), Offset(12, 7), Offset(11, 7), Offset(10, 7), Offset(9, 7),
    ],
  };

  static const Map<PlayerColor, Offset> finishCenter = {
    PlayerColor.red: Offset(7, 8),
    PlayerColor.green: Offset(6, 7),
    PlayerColor.yellow: Offset(7, 6),
    PlayerColor.blue: Offset(8, 7),
  };

  /// Yard token slots inside each corner home.
  static const Map<PlayerColor, List<Offset>> yardSlots = {
    PlayerColor.red: [
      Offset(1.5, 10.5), Offset(3.5, 10.5), Offset(1.5, 12.5), Offset(3.5, 12.5),
    ],
    PlayerColor.green: [
      Offset(1.5, 1.5), Offset(3.5, 1.5), Offset(1.5, 3.5), Offset(3.5, 3.5),
    ],
    PlayerColor.yellow: [
      Offset(10.5, 1.5), Offset(12.5, 1.5), Offset(10.5, 3.5), Offset(12.5, 3.5),
    ],
    PlayerColor.blue: [
      Offset(10.5, 10.5), Offset(12.5, 10.5), Offset(10.5, 12.5), Offset(12.5, 12.5),
    ],
  };

  /// Star / safe squares on the main track (global indices).
  static const Set<int> safeGlobalIndices = {0, 8, 13, 21, 26, 34, 39, 47};

  static Offset cellForToken(Token token) {
    if (token.inYard) {
      return yardSlots[token.color]![token.id];
    }
    if (token.finished) {
      return finishCenter[token.color]!;
    }
    if (token.onHomeStretch) {
      return homeStretch[token.color]![token.position - 51];
    }
    final global = (token.color.startIndex + token.position) % 52;
    return mainPath[global];
  }

  static int? globalIndexForToken(Token token) {
    if (!token.onMainTrack) return null;
    return (token.color.startIndex + token.position) % 52;
  }
}
