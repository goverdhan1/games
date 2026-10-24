import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class SnakeScreen extends StatefulWidget {
  const SnakeScreen({super.key});

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

enum _Dir { up, down, left, right }

class _SnakeScreenState extends State<SnakeScreen> {
  static const int cols = 20;
  static const int rows = 20;

  final Random _rng = Random();
  Timer? _tick;
  Timer? _clock;

  List<Point<int>> _snake = [];
  Point<int> _food = const Point(0, 0);
  _Dir _dir = _Dir.right;
  _Dir _pendingDir = _Dir.right;
  int _score = 0;
  int _best = 0;
  int _seconds = 0;
  bool _running = false;
  bool _over = false;
  Offset _drag = Offset.zero;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  Duration get _speed {
    final ms = max(70, 180 - (_score ~/ 5) * 10);
    return Duration(milliseconds: ms);
  }

  void _reset() {
    _tick?.cancel();
    _clock?.cancel();
    _snake = [const Point(10, 10), const Point(9, 10), const Point(8, 10)];
    _dir = _Dir.right;
    _pendingDir = _Dir.right;
    _score = 0;
    _seconds = 0;
    _running = false;
    _over = false;
    _placeFood();
  }

  void _placeFood() {
    final free = <Point<int>>[];
    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        final p = Point(x, y);
        if (!_snake.contains(p)) free.add(p);
      }
    }
    if (free.isEmpty) return;
    _food = free[_rng.nextInt(free.length)];
  }

  void _start() {
    if (_over) return;
    _running = true;
    _scheduleTick();
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running) return;
      setState(() => _seconds++);
    });
  }

  void _scheduleTick() {
    _tick?.cancel();
    _tick = Timer.periodic(_speed, (_) => _step());
  }

  void _togglePause() {
    if (_over) return;
    setState(() {
      if (_running) {
        _running = false;
        _tick?.cancel();
        _clock?.cancel();
      } else {
        _start();
      }
    });
  }

  bool _opposite(_Dir a, _Dir b) =>
      (a == _Dir.up && b == _Dir.down) ||
      (a == _Dir.down && b == _Dir.up) ||
      (a == _Dir.left && b == _Dir.right) ||
      (a == _Dir.right && b == _Dir.left);

  void _turn(_Dir d) {
    if (_over) return;
    if (_opposite(_dir, d)) return;
    _pendingDir = d;
    if (!_running) setState(_start);
  }

  void _step() {
    if (!mounted || !_running) return;
    _dir = _pendingDir;
    final head = _snake.first;
    late Point<int> next;
    switch (_dir) {
      case _Dir.up:
        next = Point(head.x, head.y - 1);
      case _Dir.down:
        next = Point(head.x, head.y + 1);
      case _Dir.left:
        next = Point(head.x - 1, head.y);
      case _Dir.right:
        next = Point(head.x + 1, head.y);
    }
    final ate = next == _food;
    // Tail moves away unless we ate, so exclude it from collision when not eating.
    final body = ate ? _snake : _snake.sublist(0, _snake.length - 1);
    final hitWall =
        next.x < 0 || next.y < 0 || next.x >= cols || next.y >= rows;
    if (hitWall || body.contains(next)) {
      setState(() {
        _over = true;
        _running = false;
        _tick?.cancel();
        _clock?.cancel();
        if (_score > _best) _best = _score;
      });
      return;
    }
    setState(() {
      _snake.insert(0, next);
      if (ate) {
        _score++;
        if (_score > _best) _best = _score;
        _placeFood();
        _scheduleTick();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _onPanEnd() {
    final dx = _drag.dx, dy = _drag.dy;
    _drag = Offset.zero;
    if (max(dx.abs(), dy.abs()) < 15) return;
    if (dx.abs() > dy.abs()) {
      _turn(dx > 0 ? _Dir.right : _Dir.left);
    } else {
      _turn(dy > 0 ? _Dir.down : _Dir.up);
    }
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake'),
        actions: [
          IconButton(
            tooltip: _running ? 'Pause' : 'Resume',
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
            onPressed: _over || (!_running && _seconds == 0 && _score == 0)
                ? null
                : _togglePause,
          ),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Score: $_score',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('Best: $_best',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('Time: ${_fmt(_seconds)}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AspectRatio(
                    aspectRatio: cols / rows,
                    child: GestureDetector(
                      onPanStart: (_) => _drag = Offset.zero,
                      onPanUpdate: (d) {
                        _drag += d.delta;
                        // Respond as soon as the swipe is long enough.
                        if (max(_drag.dx.abs(), _drag.dy.abs()) > 24) {
                          _onPanEnd();
                        }
                      },
                      onPanEnd: (_) => _onPanEnd(),
                      onTap: () {
                        if (!_running && !_over) setState(_start);
                      },
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _SnakePainter(
                                  _snake, _food, cols, rows, _over),
                            ),
                          ),
                          if (!_running)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                alignment: Alignment.center,
                                child: Text(
                                  _over
                                      ? 'Game over!\nScore $_score'
                                      : (_seconds == 0 && _score == 0
                                          ? 'Tap or swipe to start'
                                          : 'Paused'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _dpad(),
                const SizedBox(height: 6),
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
          onPressed: () => _turn(d),
          icon: Icon(i, size: 32),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        b(Icons.keyboard_arrow_up, _Dir.up),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            b(Icons.keyboard_arrow_left, _Dir.left),
            const SizedBox(width: 48),
            b(Icons.keyboard_arrow_right, _Dir.right),
          ],
        ),
        b(Icons.keyboard_arrow_down, _Dir.down),
      ],
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final int cols;
  final int rows;
  final bool dead;

  _SnakePainter(List<Point<int>> s, this.food, this.cols, this.rows, this.dead)
      : snake = List.of(s);

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols;
    final ch = size.height / rows;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1B2B1B));
    final grid = Paint()
      ..color = const Color(0xFF243824)
      ..strokeWidth = 1;
    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(Offset(i * cw, 0), Offset(i * cw, size.height), grid);
    }
    for (int j = 0; j <= rows; j++) {
      canvas.drawLine(Offset(0, j * ch), Offset(size.width, j * ch), grid);
    }
    // Food
    canvas.drawCircle(
      Offset((food.x + 0.5) * cw, (food.y + 0.5) * ch),
      min(cw, ch) * 0.38,
      Paint()..color = Colors.redAccent,
    );
    // Snake
    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x * cw + 1, p.y * ch + 1, cw - 2, ch - 2),
        Radius.circular(min(cw, ch) * 0.3),
      );
      final color = i == 0
          ? (dead ? Colors.orange : Colors.lightGreenAccent)
          : Colors.green.shade400;
      canvas.drawRRect(r, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter old) => true;
}
