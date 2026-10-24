import 'dart:math';

import 'package:flutter/material.dart';

/// Checkers (draughts): human plays Red (bottom, moves up) against a simple
/// minimax AI playing Black. Captures are mandatory, multi-jumps are supported
/// and men that reach the far row become kings.
class CheckersScreen extends StatefulWidget {
  const CheckersScreen({super.key});

  @override
  State<CheckersScreen> createState() => _CheckersScreenState();
}

typedef _CBoard = List<List<String>>;

class _CMove {
  final int fr, fc;
  final List<int> path; // encoded landing squares r*8+c
  final List<int> caps; // encoded captured squares
  const _CMove(this.fr, this.fc, this.path, this.caps);
}

_CBoard _startBoard() {
  final b = List.generate(8, (_) => List.filled(8, ''));
  for (var r = 0; r < 3; r++) {
    for (var c = 0; c < 8; c++) {
      if ((r + c) % 2 == 1) b[r][c] = 'b';
    }
  }
  for (var r = 5; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      if ((r + c) % 2 == 1) b[r][c] = 'r';
    }
  }
  return b;
}

_CBoard _cCopy(_CBoard b) => b.map((r) => List<String>.from(r)).toList();

bool _isRed(String p) => p == 'r' || p == 'R';
bool _isKing(String p) => p == 'R' || p == 'B';
bool _cIn(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

List<List<int>> _dirs(String p) {
  if (_isKing(p)) {
    return const [
      [-1, -1], [-1, 1], [1, -1], [1, 1],
    ];
  }
  return _isRed(p)
      ? const [
          [-1, -1], [-1, 1],
        ]
      : const [
          [1, -1], [1, 1],
        ];
}

void _jumpDfs(_CBoard b, String piece, int r, int c, int sr, int sc,
    List<int> path, List<int> caps, List<_CMove> out) {
  var found = false;
  for (final d in _dirs(piece)) {
    final mr = r + d[0], mc = c + d[1];
    final jr = r + 2 * d[0], jc = c + 2 * d[1];
    if (!_cIn(jr, jc)) continue;
    final mid = b[mr][mc];
    if (mid.isEmpty || _isRed(mid) == _isRed(piece)) continue;
    if (b[jr][jc].isNotEmpty) continue;
    found = true;
    final removed = b[mr][mc];
    b[mr][mc] = '';
    path.add(jr * 8 + jc);
    caps.add(mr * 8 + mc);
    final promotes = !_isKing(piece) &&
        ((_isRed(piece) && jr == 0) || (!_isRed(piece) && jr == 7));
    if (promotes) {
      // In American checkers a jump ending in promotion ends the turn.
      out.add(_CMove(sr, sc, List.of(path), List.of(caps)));
    } else {
      _jumpDfs(b, piece, jr, jc, sr, sc, path, caps, out);
    }
    path.removeLast();
    caps.removeLast();
    b[mr][mc] = removed;
  }
  if (!found && path.isNotEmpty) {
    out.add(_CMove(sr, sc, List.of(path), List.of(caps)));
  }
}

List<_CMove> _allMoves(_CBoard b, bool red) {
  final jumps = <_CMove>[];
  final steps = <_CMove>[];
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      final p = b[r][c];
      if (p.isEmpty || _isRed(p) != red) continue;
      // jumps (temporarily lift piece off its square)
      b[r][c] = '';
      _jumpDfs(b, p, r, c, r, c, <int>[], <int>[], jumps);
      b[r][c] = p;
      for (final d in _dirs(p)) {
        final nr = r + d[0], nc = c + d[1];
        if (_cIn(nr, nc) && b[nr][nc].isEmpty) {
          steps.add(_CMove(r, c, [nr * 8 + nc], const []));
        }
      }
    }
  }
  return jumps.isNotEmpty ? jumps : steps;
}

_CBoard _cApply(_CBoard b, _CMove m) {
  final nb = _cCopy(b);
  var piece = nb[m.fr][m.fc];
  nb[m.fr][m.fc] = '';
  for (final cap in m.caps) {
    nb[cap ~/ 8][cap % 8] = '';
  }
  final last = m.path.last;
  final lr = last ~/ 8, lc = last % 8;
  if (piece == 'r' && lr == 0) piece = 'R';
  if (piece == 'b' && lr == 7) piece = 'B';
  nb[lr][lc] = piece;
  return nb;
}

int _cEval(_CBoard b) {
  // positive = good for Black (AI)
  var s = 0;
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      final p = b[r][c];
      if (p.isEmpty) continue;
      var v = _isKing(p) ? 170 : 100;
      if (!_isKing(p)) {
        v += _isRed(p) ? (7 - r) * 4 : r * 4;
      }
      // prefer centre/edge safety slightly
      if (c == 0 || c == 7) v += 3;
      s += _isRed(p) ? -v : v;
    }
  }
  return s;
}

int _cSearch(_CBoard b, int depth, int alpha, int beta, bool blackToMove) {
  final moves = _allMoves(b, !blackToMove);
  if (moves.isEmpty) return blackToMove ? -100000 - depth : 100000 + depth;
  if (depth == 0) return _cEval(b);
  if (blackToMove) {
    var best = -1 << 30;
    for (final m in moves) {
      best = max(best, _cSearch(_cApply(b, m), depth - 1, alpha, beta, false));
      alpha = max(alpha, best);
      if (alpha >= beta) break;
    }
    return best;
  } else {
    var best = 1 << 30;
    for (final m in moves) {
      best = min(best, _cSearch(_cApply(b, m), depth - 1, alpha, beta, true));
      beta = min(beta, best);
      if (alpha >= beta) break;
    }
    return best;
  }
}

class _CheckersScreenState extends State<CheckersScreen> {
  final Random _rng = Random();
  late _CBoard _board;
  List<_CMove> _moves = [];
  int? _selR, _selC;
  List<int> _taps = [];
  bool _humanTurn = true;
  bool _gameOver = false;
  String _status = 'Your move (Red)';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = _startBoard();
    _moves = _allMoves(_board, true);
    _selR = _selC = null;
    _taps = [];
    _humanTurn = true;
    _gameOver = false;
    _status = 'Your move (Red)';
  }

  int _count(bool red) {
    var n = 0;
    for (final row in _board) {
      for (final p in row) {
        if (p.isNotEmpty && _isRed(p) == red) n++;
      }
    }
    return n;
  }

  void _onTap(int r, int c) {
    if (_gameOver || !_humanTurn) return;
    final sq = r * 8 + c;
    if (_selR != null) {
      final cands = _moves.where((m) =>
          m.fr == _selR &&
          m.fc == _selC &&
          m.path.length > _taps.length &&
          _prefixMatches(m));
      for (final m in cands) {
        if (m.path[_taps.length] == sq) {
          final newTaps = [..._taps, sq];
          final done = _moves.where((x) =>
              x.fr == _selR &&
              x.fc == _selC &&
              x.path.length == newTaps.length &&
              _listEq(x.path, newTaps));
          if (done.isNotEmpty) {
            _executeHuman(done.first);
          } else {
            setState(() => _taps = newTaps);
          }
          return;
        }
      }
      // only allow re-selection if we're not mid-jump
      if (_taps.isNotEmpty) return;
    }
    final p = _board[r][c];
    if (p.isNotEmpty && _isRed(p) && _moves.any((m) => m.fr == r && m.fc == c)) {
      setState(() {
        _selR = r;
        _selC = c;
        _taps = [];
      });
    } else {
      setState(() {
        _selR = _selC = null;
        _taps = [];
      });
    }
  }

  bool _prefixMatches(_CMove m) {
    for (var i = 0; i < _taps.length; i++) {
      if (m.path[i] != _taps[i]) return false;
    }
    return true;
  }

  bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _executeHuman(_CMove m) {
    setState(() {
      _board = _cApply(_board, m);
      _selR = _selC = null;
      _taps = [];
      _humanTurn = false;
      _moves = _allMoves(_board, false);
      if (_moves.isEmpty) {
        _gameOver = true;
        _status = 'You win!';
      } else {
        _status = 'Black is thinking...';
      }
    });
    if (!_gameOver) {
      Future.delayed(const Duration(milliseconds: 500), _aiMove);
    }
  }

  void _aiMove() {
    if (!mounted) return;
    final moves = _allMoves(_board, false);
    if (moves.isEmpty) {
      setState(() {
        _gameOver = true;
        _status = 'You win!';
      });
      return;
    }
    moves.shuffle(_rng);
    var best = moves.first;
    var bestScore = -1 << 30;
    for (final m in moves) {
      final s = _cSearch(_cApply(_board, m), 3, -1 << 30, 1 << 30, false);
      if (s > bestScore) {
        bestScore = s;
        best = m;
      }
    }
    setState(() {
      _board = _cApply(_board, best);
      _humanTurn = true;
      _moves = _allMoves(_board, true);
      if (_moves.isEmpty) {
        _gameOver = true;
        _status = 'Black wins. Better luck next time!';
      } else {
        final mustJump = _moves.first.caps.isNotEmpty;
        _status = mustJump ? 'Your move - you must capture!' : 'Your move (Red)';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkers'),
        actions: [
          IconButton(
            tooltip: 'New game',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_reset),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(_status, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Red: ${_count(true)}    Black: ${_count(false)}'),
                ],
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
              child: Text('Captures are mandatory. Reach the far row to be crowned.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(double cell) {
    // Next-step targets for current selection
    final targets = <int>{};
    if (_selR != null) {
      for (final m in _moves) {
        if (m.fr == _selR &&
            m.fc == _selC &&
            m.path.length > _taps.length &&
            _prefixMatches(m)) {
          targets.add(m.path[_taps.length]);
        }
      }
    }
    final movable = <int>{};
    if (_humanTurn && !_gameOver) {
      for (final m in _moves) {
        movable.add(m.fr * 8 + m.fc);
      }
    }
    return Column(
      children: List.generate(8, (r) {
        return Row(
          children: List.generate(8, (c) {
            final dark = (r + c) % 2 == 1;
            final p = _board[r][c];
            final sq = r * 8 + c;
            final selected = _selR == r && _selC == c;
            return GestureDetector(
              onTap: () => _onTap(r, c),
              child: Container(
                width: cell,
                height: cell,
                color: dark ? const Color(0xFF6D4C41) : const Color(0xFFFFE0B2),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (targets.contains(sq))
                      Container(
                        width: cell * 0.4,
                        height: cell * 0.4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xAA66BB6A),
                        ),
                      ),
                    if (_taps.contains(sq))
                      Container(
                        width: cell * 0.5,
                        height: cell * 0.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.lightGreenAccent, width: 3),
                        ),
                      ),
                    if (p.isNotEmpty) _piece(p, cell, selected, movable.contains(sq)),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _piece(String p, double cell, bool selected, bool movable) {
    final red = _isRed(p);
    return Container(
      width: cell * 0.8,
      height: cell * 0.8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: red ? const Color(0xFFD32F2F) : const Color(0xFF212121),
        border: Border.all(
          color: selected
              ? Colors.lightBlueAccent
              : (movable && red ? Colors.yellowAccent : Colors.white70),
          width: selected ? 4 : (movable && red ? 3 : 2),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: _isKing(p)
          ? Text(
              '♛',
              style: TextStyle(
                fontSize: cell * 0.5,
                color: Colors.amber,
                height: 1.0,
              ),
            )
          : null,
    );
  }
}
