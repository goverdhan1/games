import 'dart:math';

import 'board_geometry.dart';
import 'models.dart';

class MoveResult {
  final bool captured;
  final bool finishedToken;
  final bool rolledSix;
  final PlayerColor? capturedColor;
  final int? capturedTokenId;

  const MoveResult({
    this.captured = false,
    this.finishedToken = false,
    this.rolledSix = false,
    this.capturedColor,
    this.capturedTokenId,
  });

  bool get extraTurn => rolledSix || captured;
}

class GameController {
  final List<Player> players;
  final Random _rng;

  int currentPlayerIndex = 0;
  TurnPhase phase = TurnPhase.rolling;
  int? diceValue;
  List<int> movableTokenIds = [];
  PlayerColor? winner;
  String statusMessage = 'Roll the dice';
  int consecutiveSixes = 0;

  GameController({
    required List<PlayerConfig> configs,
    Random? rng,
  })  : players = configs
            .map(
              (c) => Player(color: c.color, type: c.type, name: c.name),
            )
            .toList(),
        _rng = rng ?? Random();

  Player get currentPlayer => players[currentPlayerIndex];

  bool get isGameOver => winner != null;

  /// Roll dice for the current player. Returns the face value.
  int rollDice() {
    if (phase != TurnPhase.rolling || isGameOver) {
      throw StateError('Cannot roll now');
    }
    diceValue = _rng.nextInt(6) + 1;
    if (diceValue == 6) {
      consecutiveSixes++;
    } else {
      consecutiveSixes = 0;
    }

    // Three sixes in a row: forfeit turn
    if (consecutiveSixes >= 3) {
      consecutiveSixes = 0;
      statusMessage = '${currentPlayer.name} rolled three 6s — turn skipped';
      movableTokenIds = [];
      phase = TurnPhase.selecting;
      _endTurn(extraTurn: false);
      return diceValue!;
    }

    movableTokenIds = _computeMovableTokens(currentPlayer, diceValue!);
    if (movableTokenIds.isEmpty) {
      statusMessage = '${currentPlayer.name} rolled $diceValue — no moves';
      phase = TurnPhase.selecting;
      _endTurn(extraTurn: false);
    } else {
      statusMessage = '${currentPlayer.name} rolled $diceValue — pick a token';
      phase = TurnPhase.selecting;
    }
    return diceValue!;
  }

  List<int> _computeMovableTokens(Player player, int dice) {
    final ids = <int>[];
    for (final token in player.tokens) {
      if (_canMove(token, dice)) ids.add(token.id);
    }
    return ids;
  }

  bool _canMove(Token token, int dice) {
    if (token.finished) return false;
    if (token.inYard) return dice == 6;
    final next = token.position + dice;
    if (next > 56) return false; // need exact roll to finish
    return true;
  }

  /// Apply move for [tokenId]. Returns null if illegal.
  MoveResult? moveToken(int tokenId) {
    if (phase != TurnPhase.selecting || diceValue == null || isGameOver) {
      return null;
    }
    if (!movableTokenIds.contains(tokenId)) return null;

    final player = currentPlayer;
    final token = player.tokens[tokenId];
    final dice = diceValue!;
    var captured = false;
    PlayerColor? capturedColor;
    int? capturedTokenId;
    var finishedToken = false;

    if (token.inYard) {
      token.position = 0; // enter start square
    } else {
      token.position += dice;
      if (token.position == 56) {
        finishedToken = true;
      }
    }

    // Capture check on main track only
    if (token.onMainTrack) {
      final global = BoardGeometry.globalIndexForToken(token)!;
      final isSafe = BoardGeometry.safeGlobalIndices.contains(global);
      if (!isSafe) {
        for (final other in players) {
          if (other.color == player.color) continue;
          for (final enemy in other.tokens) {
            if (!enemy.onMainTrack) continue;
            final eg = BoardGeometry.globalIndexForToken(enemy)!;
            if (eg == global) {
              enemy.position = -1;
              captured = true;
              capturedColor = enemy.color;
              capturedTokenId = enemy.id;
            }
          }
        }
      }
    }

    if (player.hasWon) {
      winner = player.color;
      phase = TurnPhase.finished;
      statusMessage = '${player.name} wins!';
      return MoveResult(
        captured: captured,
        finishedToken: finishedToken,
        rolledSix: dice == 6,
        capturedColor: capturedColor,
        capturedTokenId: capturedTokenId,
      );
    }

    final result = MoveResult(
      captured: captured,
      finishedToken: finishedToken,
      rolledSix: dice == 6,
      capturedColor: capturedColor,
      capturedTokenId: capturedTokenId,
    );

    movableTokenIds = [];
    _endTurn(extraTurn: result.extraTurn);
    return result;
  }

  void _endTurn({required bool extraTurn}) {
    diceValue = null;
    movableTokenIds = [];
    if (isGameOver) return;

    if (extraTurn) {
      phase = TurnPhase.rolling;
      statusMessage = '${currentPlayer.name} gets another turn — roll!';
      return;
    }

    consecutiveSixes = 0;
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    phase = TurnPhase.rolling;
    statusMessage = "${currentPlayer.name}'s turn — roll!";
  }

  /// Auto-pick a legal move for AI (or single movable human token).
  int? suggestTokenId() {
    if (movableTokenIds.isEmpty) return null;
    return chooseAiToken(currentPlayer, movableTokenIds, diceValue!, players);
  }
}

/// Simple heuristic AI: capture > finish > leave yard > advance farthest.
int chooseAiToken(
  Player me,
  List<int> movable,
  int dice,
  List<Player> all,
) {
  int scoreFor(Token token) {
    var score = 0;

    // Leaving yard
    if (token.inYard && dice == 6) score += 40;

    final simulated = token.position < 0 ? 0 : token.position + dice;

    // Finish
    if (simulated == 56) score += 100;

    // Capture opportunity
    if (token.inYard || (token.position >= 0 && token.position <= 50)) {
      final newPos = token.inYard ? 0 : token.position + dice;
      if (newPos <= 50) {
        final global = (me.color.startIndex + newPos) % 52;
        if (!BoardGeometry.safeGlobalIndices.contains(global)) {
          for (final other in all) {
            if (other.color == me.color) continue;
            for (final enemy in other.tokens) {
              if (!enemy.onMainTrack) continue;
              if ((enemy.color.startIndex + enemy.position) % 52 == global) {
                score += 80;
              }
            }
          }
        }
      }
    }

    // Prefer tokens further along
    score += (token.inYard ? 0 : token.position);

    // Prefer entering home stretch
    if (!token.inYard && token.position + dice >= 51 && token.position < 51) {
      score += 25;
    }

    return score;
  }

  movable.sort((a, b) {
    final sa = scoreFor(me.tokens[a]);
    final sb = scoreFor(me.tokens[b]);
    return sb.compareTo(sa);
  });
  return movable.first;
}
