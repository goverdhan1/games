import 'package:flutter/material.dart';

import '../../audio/sound_service.dart';
import 'board_geometry.dart';
import 'game_controller.dart';
import 'models.dart';
import '../../settings.dart';
import 'board_painter.dart';
import 'dice_widget.dart';

class GameScreen extends StatefulWidget {
  final List<PlayerConfig> configs;

  const GameScreen({super.key, required this.configs});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _game;
  bool _rolling = false;
  bool _busy = false;
  int? _shownDice;

  @override
  void initState() {
    super.initState();
    _game = GameController(configs: widget.configs);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunAi());
  }

  Future<void> _maybeRunAi() async {
    if (!mounted || _busy || _game.isGameOver) return;
    final player = _game.currentPlayer;
    if (player.type != PlayerType.ai) return;

    _busy = true;
    try {
      while (mounted &&
          !_game.isGameOver &&
          _game.currentPlayer.type == PlayerType.ai) {
        if (_game.phase == TurnPhase.rolling) {
          await Future<void>.delayed(const Duration(milliseconds: 650));
          if (!mounted) return;
          await _doRoll();
        }
        if (_game.isGameOver) break;
        if (_game.phase == TurnPhase.selecting &&
            _game.movableTokenIds.isNotEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 450));
          if (!mounted) return;
          final id = _game.suggestTokenId();
          if (id != null) {
            await _doMove(id);
          }
        } else {
          break;
        }
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _doRoll() async {
    if (_game.phase != TurnPhase.rolling || _game.isGameOver) return;
    setState(() => _rolling = true);
    SoundService.instance.dice();
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    final value = _game.rollDice();
    setState(() {
      _shownDice = value;
      _rolling = false;
    });
    // Brief pause so player sees the result when turn auto-advances
    if (_game.movableTokenIds.isEmpty && !_game.isGameOver) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() {});
    }
  }

  Future<void> _doMove(int tokenId) async {
    final result = _game.moveToken(tokenId);
    if (result == null) return;
    if (result.captured) {
      SoundService.instance.capture();
    } else {
      SoundService.instance.move();
    }
    if (result.finishedToken || _game.isGameOver) {
      SoundService.instance.win();
    }
    setState(() {
      _shownDice = _game.diceValue;
    });
    if (_game.isGameOver && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) _showWinDialog();
    }
  }

  void _onRollTap() {
    if (_busy || _rolling) return;
    if (_game.currentPlayer.type != PlayerType.human) return;
    if (_game.phase != TurnPhase.rolling) return;
    _busy = true;
    _doRoll().then((_) {
      _busy = false;
      _maybeRunAi();
    });
  }

  void _onBoardTap(Offset local, double boardSize) {
    if (_busy || _game.isGameOver) return;
    if (_game.currentPlayer.type != PlayerType.human) return;
    if (_game.phase != TurnPhase.selecting) return;
    if (_game.movableTokenIds.isEmpty) return;

    final cell = boardSize / BoardGeometry.size;
    final player = _game.currentPlayer;
    int? bestId;
    var bestDist = double.infinity;

    for (final id in _game.movableTokenIds) {
      final token = player.tokens[id];
      final pos = BoardGeometry.cellForToken(token);
      final point = token.inYard
          ? Offset(pos.dx * cell, pos.dy * cell)
          : Offset((pos.dx + 0.5) * cell, (pos.dy + 0.5) * cell);
      final d = (point - local).distance;
      if (d < bestDist) {
        bestDist = d;
        bestId = id;
      }
    }

    if (bestId != null && bestDist < cell * 1.2) {
      _busy = true;
      _doMove(bestId).then((_) {
        _busy = false;
        _maybeRunAi();
      });
    }
  }

  void _showWinDialog() {
    final winner = _game.players.firstWhere((p) => p.color == _game.winner);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Victory!'),
        content: Text('${winner.name} (${winner.color.label}) wins the game.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _game = GameController(configs: widget.configs);
                _shownDice = null;
                _rolling = false;
                _busy = false;
              });
              _maybeRunAi();
            },
            child: const Text('Play again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = _game.currentPlayer;
    final canRoll = !_busy &&
        !_rolling &&
        !_game.isGameOver &&
        player.type == PlayerType.human &&
        _game.phase == TurnPhase.rolling;

    return Scaffold(
      backgroundColor: const Color(0xFF0E3B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E3B2E),
        foregroundColor: Colors.white,
        title: const Text('Ludo'),
        actions: [
          IconButton(
            tooltip: 'Sound',
            onPressed: () async {
              setState(() {
                AppSettings.instance.soundEnabled =
                    !AppSettings.instance.soundEnabled;
              });
              await AppSettings.instance.save();
            },
            icon: Icon(
              AppSettings.instance.soundEnabled
                  ? Icons.volume_up
                  : Icons.volume_off,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  for (final p in _game.players) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: p.color == player.color
                              ? p.color.color
                              : p.color.color.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: p.color == player.color
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.color == PlayerColor.yellow
                                    ? Colors.black87
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${p.finishedCount}/4',
                              style: TextStyle(
                                color: p.color == PlayerColor.yellow
                                    ? Colors.black54
                                    : Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (p != _game.players.last) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth - 16
                        : constraints.maxHeight - 16;
                    return GestureDetector(
                      onTapUp: (d) => _onBoardTap(d.localPosition, side),
                      child: Container(
                        width: side,
                        height: side,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CustomPaint(
                          size: Size(side, side),
                          painter: BoardPainter(
                            game: _game,
                            highlightTokenIds:
                                _game.movableTokenIds.toSet(),
                            highlightColor: _game.phase == TurnPhase.selecting
                                ? player.color
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _game.statusMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DiceWidget(
                    value: _shownDice,
                    enabled: canRoll,
                    rolling: _rolling,
                    onTap: _onRollTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
