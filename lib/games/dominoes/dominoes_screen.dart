import 'dart:math';

import 'package:flutter/material.dart';

/// Double-six dominoes: you versus the CPU. Match the open ends of the chain.
class DominoesScreen extends StatefulWidget {
  const DominoesScreen({super.key});

  @override
  State<DominoesScreen> createState() => _DominoesScreenState();
}

class _Dom {
  final int a;
  final int b;
  const _Dom(this.a, this.b);

  _Dom get flipped => _Dom(b, a);
  int get pips => a + b;
  bool get isDouble => a == b;
}

class _DominoesScreenState extends State<DominoesScreen> {
  final Random _rng = Random();

  List<_Dom> _yard = [];
  List<_Dom> _player = [];
  List<_Dom> _cpu = [];
  List<_Dom> _chain = [];

  bool _playerTurn = true;
  bool _over = false;
  String _msg = '';
  int _passes = 0;
  int? _pending; // hand index awaiting a left/right choice
  int _gen = 0; // invalidates scheduled CPU moves on restart

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  int get _leftEnd => _chain.first.a;
  int get _rightEnd => _chain.last.b;

  bool _canLeft(_Dom t) => t.a == _leftEnd || t.b == _leftEnd;
  bool _canRight(_Dom t) => t.a == _rightEnd || t.b == _rightEnd;
  bool _canPlay(_Dom t) => _canLeft(t) || _canRight(t);

  void _newGame() {
    _gen++;
    final all = <_Dom>[];
    for (var i = 0; i <= 6; i++) {
      for (var j = i; j <= 6; j++) {
        all.add(_Dom(i, j));
      }
    }
    all.shuffle(_rng);
    _player = all.sublist(0, 7);
    _cpu = all.sublist(7, 14);
    _yard = all.sublist(14);
    _chain = [];
    _over = false;
    _passes = 0;
    _pending = null;

    // Highest double (or highest tile) opens the game.
    _Dom? best;
    var bestIsPlayer = true;
    int score(_Dom t) => (t.isDouble ? 100 : 0) + t.pips;
    for (final t in _player) {
      if (best == null || score(t) > score(best)) {
        best = t;
        bestIsPlayer = true;
      }
    }
    for (final t in _cpu) {
      if (score(t) > score(best!)) {
        best = t;
        bestIsPlayer = false;
      }
    }
    if (bestIsPlayer) {
      _player.remove(best);
    } else {
      _cpu.remove(best);
    }
    _chain.add(best!);
    _playerTurn = !bestIsPlayer;
    _msg = bestIsPlayer
        ? 'You opened with ${best.a}|${best.b}. CPU to move...'
        : 'CPU opened with ${best.a}|${best.b}. Your move!';
    setState(() {});
    if (!_playerTurn) _scheduleCpu();
  }

  void _scheduleCpu() {
    final gen = _gen;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || gen != _gen || _over) return;
      _cpuMove();
    });
  }

  void _place(List<_Dom> hand, int idx, bool left) {
    final t = hand.removeAt(idx);
    if (left) {
      _chain.insert(0, t.b == _leftEnd ? t : t.flipped);
    } else {
      _chain.add(t.a == _rightEnd ? t : t.flipped);
    }
    _passes = 0;
  }

  void _finishIfDone() {
    if (_player.isEmpty) {
      _over = true;
      _msg = 'You win! All your tiles are played.';
    } else if (_cpu.isEmpty) {
      _over = true;
      _msg = 'CPU wins this round.';
    } else if (_passes >= 2) {
      _over = true;
      final p = _player.fold<int>(0, (s, t) => s + t.pips);
      final c = _cpu.fold<int>(0, (s, t) => s + t.pips);
      if (p < c) {
        _msg = 'Blocked! You win on pips ($p vs $c).';
      } else if (c < p) {
        _msg = 'Blocked! CPU wins on pips ($c vs $p).';
      } else {
        _msg = 'Blocked! It is a tie ($p each).';
      }
    }
  }

  void _onHandTap(int i) {
    if (!_playerTurn || _over) return;
    final t = _player[i];
    final l = _canLeft(t);
    final r = _canRight(t);
    if (!l && !r) {
      setState(() => _msg = 'That tile does not match either end.');
      return;
    }
    if (l && r && _leftEnd != _rightEnd) {
      setState(() {
        _pending = i;
        _msg = 'Choose which end to play ${t.a}|${t.b} on.';
      });
      return;
    }
    _playerPlay(i, r);
  }

  void _playerPlay(int i, bool right) {
    setState(() {
      _pending = null;
      _place(_player, i, !right);
      _finishIfDone();
      if (!_over) {
        _playerTurn = false;
        _msg = 'CPU is thinking...';
      }
    });
    if (!_over) _scheduleCpu();
  }

  void _playerDraw() {
    if (!_playerTurn || _over || _yard.isEmpty) return;
    setState(() {
      _player.add(_yard.removeLast());
      _msg = 'You drew a tile.';
    });
  }

  void _playerPass() {
    if (!_playerTurn || _over) return;
    setState(() {
      _passes++;
      _finishIfDone();
      if (!_over) {
        _playerTurn = false;
        _msg = 'You passed. CPU to move...';
      }
    });
    if (!_over) _scheduleCpu();
  }

  void _cpuMove() {
    while (_cpu.every((t) => !_canPlay(t)) && _yard.isNotEmpty) {
      _cpu.add(_yard.removeLast());
    }
    final playable = <int>[];
    for (var i = 0; i < _cpu.length; i++) {
      if (_canPlay(_cpu[i])) playable.add(i);
    }
    setState(() {
      if (playable.isEmpty) {
        _passes++;
        _msg = 'CPU passes. Your move!';
      } else {
        playable.sort((x, y) {
          final tx = _cpu[x];
          final ty = _cpu[y];
          final sx = (tx.isDouble ? 20 : 0) + tx.pips;
          final sy = (ty.isDouble ? 20 : 0) + ty.pips;
          return sy.compareTo(sx);
        });
        final idx = playable.first;
        final t = _cpu[idx];
        final goRight = _canRight(t);
        _place(_cpu, idx, !goRight);
        _msg = 'CPU played ${t.a}|${t.b}. Your move!';
      }
      _finishIfDone();
      if (!_over) _playerTurn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasMove = _player.any(_canPlay);
    final canDraw =
        _playerTurn && !_over && !hasMove && _yard.isNotEmpty;
    final canPass =
        _playerTurn && !_over && !hasMove && _yard.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1B3A2F),
      appBar: AppBar(
        title: const Text('Dominoes'),
        backgroundColor: const Color(0xFF455A64),
        foregroundColor: Colors.white,
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
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _chip(Icons.smart_toy, 'CPU: ${_cpu.length} tiles',
                      !_playerTurn && !_over),
                  _chip(Icons.inventory_2, 'Boneyard: ${_yard.length}', false),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14291F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 6,
                    children: [
                      for (final t in _chain)
                        _DominoView(tile: t, horizontal: true, size: 26),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                _msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            if (_pending != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _playerPlay(_pending!, false),
                    child: Text('Left end ($_leftEnd)'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _playerPlay(_pending!, true),
                    child: Text('Right end ($_rightEnd)'),
                  ),
                ],
              ),
            if (canDraw || canPass || _over)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (canDraw)
                      ElevatedButton.icon(
                        onPressed: _playerDraw,
                        icon: const Icon(Icons.download),
                        label: const Text('Draw tile'),
                      ),
                    if (canPass)
                      ElevatedButton.icon(
                        onPressed: _playerPass,
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Pass'),
                      ),
                    if (_over)
                      ElevatedButton.icon(
                        onPressed: _newGame,
                        icon: const Icon(Icons.replay),
                        label: const Text('Play again'),
                      ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF263238),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _player.length; i++)
                    GestureDetector(
                      onTap: () => _onHandTap(i),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _playerTurn && !_over && _canPlay(_player[i])
                                ? Colors.amber
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _DominoView(
                          tile: _player[i],
                          horizontal: false,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.amber.shade700 : Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _DominoView extends StatelessWidget {
  final _Dom tile;
  final bool horizontal;
  final double size; // edge length of one half

  const _DominoView({
    required this.tile,
    required this.horizontal,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final halves = [
      SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PipPainter(tile.a)),
      ),
      Container(
        width: horizontal ? 1.5 : size * 0.8,
        height: horizontal ? size * 0.8 : 1.5,
        color: Colors.black54,
      ),
      SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PipPainter(tile.b)),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E0),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black87, width: 1),
      ),
      child: horizontal
          ? Row(mainAxisSize: MainAxisSize.min, children: halves)
          : Column(mainAxisSize: MainAxisSize.min, children: halves),
    );
  }
}

class _PipPainter extends CustomPainter {
  final int n;
  const _PipPainter(this.n);

  static const _tl = Offset(0.28, 0.28);
  static const _tr = Offset(0.72, 0.28);
  static const _ml = Offset(0.28, 0.5);
  static const _mr = Offset(0.72, 0.5);
  static const _bl = Offset(0.28, 0.72);
  static const _br = Offset(0.72, 0.72);
  static const _c = Offset(0.5, 0.5);

  static const Map<int, List<Offset>> _layout = {
    0: [],
    1: [_c],
    2: [_tl, _br],
    3: [_tl, _c, _br],
    4: [_tl, _tr, _bl, _br],
    5: [_tl, _tr, _c, _bl, _br],
    6: [_tl, _tr, _ml, _mr, _bl, _br],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black87;
    final r = size.shortestSide * 0.09;
    for (final o in _layout[n]!) {
      canvas.drawCircle(Offset(o.dx * size.width, o.dy * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _PipPainter old) => old.n != n;
}
