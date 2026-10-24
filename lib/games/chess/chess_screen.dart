import 'dart:math';

import 'package:flutter/material.dart';

/// Chess: human plays White, a simple 2-ply AI plays Black.
/// Rules implemented: all piece moves, check/checkmate/stalemate detection,
/// pawn promotion (auto-queen). Castling and en passant are omitted.
class ChessScreen extends StatefulWidget {
  const ChessScreen({super.key});

  @override
  State<ChessScreen> createState() => _ChessScreenState();
}

class _ChessMove {
  final int fr, fc, tr, tc;
  const _ChessMove(this.fr, this.fc, this.tr, this.tc);
}

typedef _Board = List<List<String>>;

bool _isWhitePiece(String p) => p.isNotEmpty && p == p.toUpperCase();

_Board _initialBoard() {
  const back = ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r'];
  final b = List.generate(8, (_) => List.filled(8, ''));
  for (var c = 0; c < 8; c++) {
    b[0][c] = back[c];
    b[1][c] = 'p';
    b[6][c] = 'P';
    b[7][c] = back[c].toUpperCase();
  }
  return b;
}

_Board _copy(_Board b) => b.map((r) => List<String>.from(r)).toList();

bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

const _knightD = [
  [-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1],
];
const _kingD = [
  [-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1],
];
const _diagD = [
  [-1, -1], [-1, 1], [1, -1], [1, 1],
];
const _orthoD = [
  [-1, 0], [1, 0], [0, -1], [0, 1],
];

/// Target squares for a piece. If [attacksOnly], pawns return their diagonal
/// attack squares (regardless of occupant) instead of pushes/captures.
List<List<int>> _targets(_Board b, int r, int c, {bool attacksOnly = false}) {
  final piece = b[r][c];
  final white = _isWhitePiece(piece);
  final t = piece.toLowerCase();
  final res = <List<int>>[];

  bool friendly(int rr, int cc) =>
      b[rr][cc].isNotEmpty && _isWhitePiece(b[rr][cc]) == white;
  bool enemy(int rr, int cc) =>
      b[rr][cc].isNotEmpty && _isWhitePiece(b[rr][cc]) != white;

  void slide(List<List<int>> dirs) {
    for (final d in dirs) {
      var rr = r + d[0], cc = c + d[1];
      while (_inBounds(rr, cc)) {
        if (friendly(rr, cc)) break;
        res.add([rr, cc]);
        if (enemy(rr, cc)) break;
        rr += d[0];
        cc += d[1];
      }
    }
  }

  void step(List<List<int>> dirs) {
    for (final d in dirs) {
      final rr = r + d[0], cc = c + d[1];
      if (_inBounds(rr, cc) && !friendly(rr, cc)) res.add([rr, cc]);
    }
  }

  switch (t) {
    case 'p':
      final dir = white ? -1 : 1;
      final startRow = white ? 6 : 1;
      if (attacksOnly) {
        for (final dc in [-1, 1]) {
          if (_inBounds(r + dir, c + dc)) res.add([r + dir, c + dc]);
        }
      } else {
        if (_inBounds(r + dir, c) && b[r + dir][c].isEmpty) {
          res.add([r + dir, c]);
          if (r == startRow && b[r + 2 * dir][c].isEmpty) {
            res.add([r + 2 * dir, c]);
          }
        }
        for (final dc in [-1, 1]) {
          final rr = r + dir, cc = c + dc;
          if (_inBounds(rr, cc) && enemy(rr, cc)) res.add([rr, cc]);
        }
      }
      break;
    case 'n':
      step(_knightD);
      break;
    case 'k':
      step(_kingD);
      break;
    case 'b':
      slide(_diagD);
      break;
    case 'r':
      slide(_orthoD);
      break;
    case 'q':
      slide(_diagD);
      slide(_orthoD);
      break;
  }
  return res;
}

bool _inCheck(_Board b, bool white) {
  final king = white ? 'K' : 'k';
  int kr = -1, kc = -1;
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      if (b[r][c] == king) {
        kr = r;
        kc = c;
      }
    }
  }
  if (kr < 0) return true; // king captured (should not happen)
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      final p = b[r][c];
      if (p.isEmpty || _isWhitePiece(p) == white) continue;
      for (final t in _targets(b, r, c, attacksOnly: true)) {
        if (t[0] == kr && t[1] == kc) return true;
      }
    }
  }
  return false;
}

_Board _applyMove(_Board b, _ChessMove m) {
  final nb = _copy(b);
  var piece = nb[m.fr][m.fc];
  nb[m.fr][m.fc] = '';
  if (piece == 'P' && m.tr == 0) piece = 'Q';
  if (piece == 'p' && m.tr == 7) piece = 'q';
  nb[m.tr][m.tc] = piece;
  return nb;
}

List<_ChessMove> _legalMoves(_Board b, bool white) {
  final moves = <_ChessMove>[];
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      final p = b[r][c];
      if (p.isEmpty || _isWhitePiece(p) != white) continue;
      for (final t in _targets(b, r, c)) {
        final m = _ChessMove(r, c, t[0], t[1]);
        if (!_inCheck(_applyMove(b, m), white)) moves.add(m);
      }
    }
  }
  return moves;
}

const _values = {'p': 100, 'n': 320, 'b': 330, 'r': 500, 'q': 900, 'k': 0};

int _evaluate(_Board b) {
  var score = 0;
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      final p = b[r][c];
      if (p.isEmpty) continue;
      final t = p.toLowerCase();
      var v = _values[t]!;
      // small centre bonus
      final centre = 3.5 - ((r - 3.5).abs() + (c - 3.5).abs()) / 2;
      if (t == 'p' || t == 'n' || t == 'b') v += (centre * 6).round();
      // pawn advancement
      if (t == 'p') {
        v += _isWhitePiece(p) ? (6 - r) * 4 : (r - 1) * 4;
      }
      score += _isWhitePiece(p) ? v : -v;
    }
  }
  return score;
}

int _search(_Board b, int depth, int alpha, int beta, bool whiteToMove) {
  final moves = _legalMoves(b, whiteToMove);
  if (moves.isEmpty) {
    if (_inCheck(b, whiteToMove)) {
      return whiteToMove ? -100000 - depth : 100000 + depth;
    }
    return 0;
  }
  if (depth == 0) return _evaluate(b);
  // captures first
  moves.sort((a, c) {
    final av = b[a.tr][a.tc].isEmpty ? 0 : 1;
    final cv = b[c.tr][c.tc].isEmpty ? 0 : 1;
    return cv - av;
  });
  if (whiteToMove) {
    var best = -1 << 30;
    for (final m in moves) {
      best = max(best, _search(_applyMove(b, m), depth - 1, alpha, beta, false));
      alpha = max(alpha, best);
      if (alpha >= beta) break;
    }
    return best;
  } else {
    var best = 1 << 30;
    for (final m in moves) {
      best = min(best, _search(_applyMove(b, m), depth - 1, alpha, beta, true));
      beta = min(beta, best);
      if (alpha >= beta) break;
    }
    return best;
  }
}

class _ChessScreenState extends State<ChessScreen> {
  static const _glyphs = {
    'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
  };

  final Random _rng = Random();
  late _Board _board;
  int? _selR, _selC;
  List<_ChessMove> _selMoves = [];
  bool _whiteTurn = true;
  bool _thinking = false;
  bool _gameOver = false;
  String _status = 'Your move (White)';
  _ChessMove? _last;

  @override
  void initState() {
    super.initState();
    _board = _initialBoard();
  }

  void _newGame() {
    setState(() {
      _board = _initialBoard();
      _selR = _selC = null;
      _selMoves = [];
      _whiteTurn = true;
      _thinking = false;
      _gameOver = false;
      _last = null;
      _status = 'Your move (White)';
    });
  }

  void _updateStatus() {
    final moves = _legalMoves(_board, _whiteTurn);
    final check = _inCheck(_board, _whiteTurn);
    if (moves.isEmpty) {
      _gameOver = true;
      if (check) {
        _status = _whiteTurn ? 'Checkmate! Black wins.' : 'Checkmate! You win!';
      } else {
        _status = 'Stalemate - draw.';
      }
    } else if (_whiteTurn) {
      _status = check ? 'Check! Your move' : 'Your move (White)';
    } else {
      _status = 'Black is thinking...';
    }
  }

  void _onTap(int r, int c) {
    if (_gameOver || !_whiteTurn || _thinking) return;
    // try move
    if (_selR != null) {
      for (final m in _selMoves) {
        if (m.tr == r && m.tc == c) {
          _play(m);
          return;
        }
      }
    }
    final p = _board[r][c];
    if (p.isNotEmpty && _isWhitePiece(p)) {
      setState(() {
        _selR = r;
        _selC = c;
        _selMoves = _legalMoves(_board, true)
            .where((m) => m.fr == r && m.fc == c)
            .toList();
      });
    } else {
      setState(() {
        _selR = _selC = null;
        _selMoves = [];
      });
    }
  }

  void _play(_ChessMove m) {
    setState(() {
      _board = _applyMove(_board, m);
      _last = m;
      _selR = _selC = null;
      _selMoves = [];
      _whiteTurn = !_whiteTurn;
      _updateStatus();
    });
    if (!_gameOver && !_whiteTurn) {
      _thinking = true;
      Future.delayed(const Duration(milliseconds: 350), _aiMove);
    }
  }

  void _aiMove() {
    if (!mounted) return;
    final moves = _legalMoves(_board, false);
    if (moves.isEmpty) {
      setState(() {
        _thinking = false;
        _updateStatus();
      });
      return;
    }
    moves.shuffle(_rng);
    _ChessMove best = moves.first;
    var bestScore = 1 << 30;
    for (final m in moves) {
      final s = _search(_applyMove(_board, m), 1, -1 << 30, 1 << 30, true);
      if (s < bestScore) {
        bestScore = s;
        best = m;
      }
    }
    setState(() {
      _thinking = false;
      _board = _applyMove(_board, best);
      _last = best;
      _whiteTurn = true;
      _updateStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess'),
        actions: [
          IconButton(
            tooltip: 'New game',
            icon: const Icon(Icons.refresh),
            onPressed: _newGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _status,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, cons) {
                    final size = min(cons.maxWidth, cons.maxHeight) - 16;
                    return SizedBox(
                      width: size,
                      height: size,
                      child: _buildBoard(size / 8),
                    );
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('You are White (bottom). Tap a piece, then a square.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(double cell) {
    final checkWhite = _inCheck(_board, true);
    final checkBlack = _inCheck(_board, false);
    return Column(
      children: List.generate(8, (r) {
        return Row(
          children: List.generate(8, (c) {
            final light = (r + c) % 2 == 0;
            final p = _board[r][c];
            Color bg = light ? const Color(0xFFEEEED2) : const Color(0xFF769656);
            if (_last != null &&
                ((_last!.fr == r && _last!.fc == c) ||
                    (_last!.tr == r && _last!.tc == c))) {
              bg = light ? const Color(0xFFF6F669) : const Color(0xFFBACA2B);
            }
            if (_selR == r && _selC == c) bg = const Color(0xFF64B5F6);
            if ((p == 'K' && checkWhite) || (p == 'k' && checkBlack)) {
              bg = const Color(0xFFE57373);
            }
            final isTarget = _selMoves.any((m) => m.tr == r && m.tc == c);
            return GestureDetector(
              onTap: () => _onTap(r, c),
              child: Container(
                width: cell,
                height: cell,
                color: bg,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (p.isNotEmpty)
                      Text(
                        _glyphs[p.toLowerCase()]!,
                        style: TextStyle(
                          fontSize: cell * 0.78,
                          height: 1.0,
                          color: _isWhitePiece(p)
                              ? Colors.white
                              : Colors.black,
                          shadows: _isWhitePiece(p)
                              ? const [
                                  Shadow(color: Colors.black, blurRadius: 2),
                                  Shadow(color: Colors.black, blurRadius: 2),
                                  Shadow(color: Colors.black, blurRadius: 1),
                                ]
                              : const [
                                  Shadow(color: Colors.white54, blurRadius: 1),
                                ],
                        ),
                      ),
                    if (isTarget)
                      Container(
                        width: p.isEmpty ? cell * 0.3 : cell * 0.9,
                        height: p.isEmpty ? cell * 0.3 : cell * 0.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.isEmpty
                              ? Colors.black.withAlpha(60)
                              : Colors.transparent,
                          border: p.isEmpty
                              ? null
                              : Border.all(
                                  color: Colors.red.withAlpha(180),
                                  width: 3,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
