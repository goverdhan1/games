import 'dart:math';

import 'package:flutter/material.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

enum _Dir { up, down, left, right }

class _Game2048ScreenState extends State<Game2048Screen> {
  static const int n = 4;
  final Random _rng = Random();
  List<List<int>> _grid = [];
  int _score = 0;
  int _best = 0;
  bool _won = false;
  bool _keepPlaying = false;
  bool _over = false;
  Offset _drag = Offset.zero;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _grid = List.generate(n, (_) => List.filled(n, 0));
    _score = 0;
    _won = false;
    _keepPlaying = false;
    _over = false;
    _spawn();
    _spawn();
  }

  void _spawn() {
    final empty = <Point<int>>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_grid[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final p = empty[_rng.nextInt(empty.length)];
    _grid[p.x][p.y] = _rng.nextInt(10) == 0 ? 4 : 2;
  }

  // Slide a single line toward index 0, returns new line and gained score.
  (List<int>, int) _slideLine(List<int> line) {
    final tiles = line.where((v) => v != 0).toList();
    final out = <int>[];
    int gained = 0;
    int i = 0;
    while (i < tiles.length) {
      if (i + 1 < tiles.length && tiles[i] == tiles[i + 1]) {
        final m = tiles[i] * 2;
        out.add(m);
        gained += m;
        i += 2;
      } else {
        out.add(tiles[i]);
        i++;
      }
    }
    while (out.length < n) {
      out.add(0);
    }
    return (out, gained);
  }

  bool _move(_Dir d) {
    bool moved = false;
    int gained = 0;
    final next = List.generate(n, (_) => List.filled(n, 0));
    for (int k = 0; k < n; k++) {
      final line = <int>[];
      for (int j = 0; j < n; j++) {
        switch (d) {
          case _Dir.left:
            line.add(_grid[k][j]);
          case _Dir.right:
            line.add(_grid[k][n - 1 - j]);
          case _Dir.up:
            line.add(_grid[j][k]);
          case _Dir.down:
            line.add(_grid[n - 1 - j][k]);
        }
      }
      final (res, g) = _slideLine(line);
      gained += g;
      for (int j = 0; j < n; j++) {
        switch (d) {
          case _Dir.left:
            next[k][j] = res[j];
          case _Dir.right:
            next[k][n - 1 - j] = res[j];
          case _Dir.up:
            next[j][k] = res[j];
          case _Dir.down:
            next[n - 1 - j][k] = res[j];
        }
      }
    }
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (next[r][c] != _grid[r][c]) moved = true;
      }
    }
    if (!moved) return false;
    _grid = next;
    _score += gained;
    if (_score > _best) _best = _score;
    _spawn();
    if (!_keepPlaying && _grid.any((row) => row.any((v) => v >= 2048))) {
      _won = true;
    }
    if (!_canMove()) _over = true;
    return true;
  }

  bool _canMove() {
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_grid[r][c] == 0) return true;
        if (c + 1 < n && _grid[r][c] == _grid[r][c + 1]) return true;
        if (r + 1 < n && _grid[r][c] == _grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  void _doMove(_Dir d) {
    if (_over || (_won && !_keepPlaying)) return;
    setState(() => _move(d));
  }

  void _onPanEnd() {
    final dx = _drag.dx, dy = _drag.dy;
    _drag = Offset.zero;
    if (max(dx.abs(), dy.abs()) < 20) return;
    if (dx.abs() > dy.abs()) {
      _doMove(dx > 0 ? _Dir.right : _Dir.left);
    } else {
      _doMove(dy > 0 ? _Dir.down : _Dir.up);
    }
  }

  Color _tileColor(int v) {
    switch (v) {
      case 0:
        return const Color(0xFFCDC1B4);
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      default:
        return const Color(0xFFEDC22E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_reset),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _scoreBox('SCORE', _score),
                      _scoreBox('BEST', _best),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onPanStart: (_) => _drag = Offset.zero,
                        onPanUpdate: (d) => _drag += d.delta,
                        onPanEnd: (_) => _onPanEnd(),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBBADA0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  for (int r = 0; r < n; r++)
                                    Expanded(
                                      child: Row(
                                        children: [
                                          for (int c = 0; c < n; c++)
                                            Expanded(child: _tile(_grid[r][c])),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_over || (_won && !_keepPlaying)) _overlay(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Swipe (or use the buttons) to merge tiles.',
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  _dpad(),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => setState(_reset),
                    icon: const Icon(Icons.replay),
                    label: const Text('Restart'),
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }

  Widget _dpad() {
    Widget b(IconData i, _Dir d) => IconButton.filledTonal(
          onPressed: () => _doMove(d),
          icon: Icon(i),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        b(Icons.keyboard_arrow_up, _Dir.up),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            b(Icons.keyboard_arrow_left, _Dir.left),
            const SizedBox(width: 40),
            b(Icons.keyboard_arrow_right, _Dir.right),
          ],
        ),
        b(Icons.keyboard_arrow_down, _Dir.down),
      ],
    );
  }

  Widget _overlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _over ? 'Game over!' : 'You reached 2048! 🎉',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => setState(_reset),
              child: const Text('Try again'),
            ),
            if (!_over)
              TextButton(
                onPressed: () => setState(() => _keepPlaying = true),
                child: const Text('Keep going'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFEEE4DA),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          Text('$value',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _tile(int v) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _tileColor(v),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: v == 0
            ? null
            : FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    '$v',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: v <= 4
                          ? const Color(0xFF776E65)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
