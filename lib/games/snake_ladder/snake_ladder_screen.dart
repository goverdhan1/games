import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class SnakeLadderScreen extends StatefulWidget {
  const SnakeLadderScreen({super.key});

  @override
  State<SnakeLadderScreen> createState() => _SnakeLadderScreenState();
}

class _SnakeLadderScreenState extends State<SnakeLadderScreen> {
  static const Map<int, int> _ladders = {
    4: 25,
    13: 46,
    27: 53,
    33: 49,
    42: 63,
    50: 69,
    62: 81,
    74: 92,
  };
  static const Map<int, int> _snakes = {
    99: 41,
    95: 75,
    89: 51,
    76: 37,
    66: 24,
    54: 34,
    43: 17,
    31: 7,
  };

  final Random _rng = Random();
  Timer? _timer;

  int _you = 0;
  int _ai = 0;
  int _dice = 1;
  bool _yourTurn = true;
  bool _busy = false;
  bool _over = false;
  String _message = 'Your turn - roll the dice!';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _you = 0;
      _ai = 0;
      _dice = 1;
      _yourTurn = true;
      _busy = false;
      _over = false;
      _message = 'Your turn - roll the dice!';
    });
  }

  void _roll() {
    if (_over || _busy || !_yourTurn) return;
    _takeTurn(true);
  }

  void _takeTurn(bool human) {
    final roll = _rng.nextInt(6) + 1;
    final name = human ? 'You' : 'AI';
    int pos = human ? _you : _ai;
    String msg = '$name rolled $roll. ';
    setState(() {
      _busy = true;
      _dice = roll;
    });

    if (pos + roll > 100) {
      msg += 'Need exact roll to reach 100.';
    } else {
      pos += roll;
      if (_ladders.containsKey(pos)) {
        final to = _ladders[pos]!;
        msg += 'Ladder! $pos -> $to.';
        pos = to;
      } else if (_snakes.containsKey(pos)) {
        final to = _snakes[pos]!;
        msg += 'Snake! $pos -> $to.';
        pos = to;
      } else {
        msg += 'Moved to $pos.';
      }
    }

    final newPos = pos;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        if (human) {
          _you = newPos;
        } else {
          _ai = newPos;
        }
        _message = msg;
        if (newPos == 100) {
          _over = true;
          _busy = false;
          _message = human ? 'You win! 🎉' : 'AI wins!';
          return;
        }
        // Rolling a 6 gives another turn.
        final again = roll == 6;
        if (again) {
          _message = '$msg Rolled a 6 - roll again!';
          _busy = false;
          _yourTurn = human;
          if (!human) _scheduleAi();
        } else {
          _yourTurn = !human;
          _busy = false;
          if (!human) {
            _message = '$msg Your turn.';
          } else {
            _message = '$msg AI is thinking...';
            _scheduleAi();
          }
        }
      });
    });
  }

  void _scheduleAi() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _over) return;
      _takeTurn(false);
    });
  }

  // Cell number -> (row from top, col)
  Offset _cellPos(int n) {
    final idx = n - 1;
    final rowFromBottom = idx ~/ 10;
    final colInRow = idx % 10;
    final col = rowFromBottom.isEven ? colInRow : 9 - colInRow;
    final row = 9 - rowFromBottom;
    return Offset(col.toDouble(), row.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake & Ladder'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh),
            onPressed: _restart,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _playerChip('You', _you, Colors.blue, _yourTurn && !_over),
                  _playerChip('AI', _ai, Colors.red, !_yourTurn && !_over),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AspectRatio(aspectRatio: 1, child: _board()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black87, width: 2),
                    ),
                    child: Text(
                      '$_dice',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  if (_over)
                    FilledButton.icon(
                      onPressed: _restart,
                      icon: const Icon(Icons.replay),
                      label: const Text('Play again'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: (_yourTurn && !_busy) ? _roll : null,
                      icon: const Icon(Icons.casino),
                      label: const Text('Roll dice'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerChip(String name, int pos, Color color, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.25 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: active ? 3 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 8, backgroundColor: color),
          const SizedBox(width: 8),
          Text('$name: ${pos == 0 ? "start" : pos}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _board() {
    return LayoutBuilder(builder: (context, c) {
      final size = min(c.maxWidth, c.maxHeight);
      final cell = size / 10;
      final children = <Widget>[];
      for (int n = 1; n <= 100; n++) {
        final p = _cellPos(n);
        Color bg = (p.dx + p.dy) % 2 == 0
            ? const Color(0xFFFFF3C4)
            : const Color(0xFFC8E6C9);
        if (_ladders.containsKey(n)) bg = const Color(0xFFFFCC80);
        if (_snakes.containsKey(n)) bg = const Color(0xFFEF9A9A);
        if (n == 100) bg = Colors.amber;
        children.add(Positioned(
          left: p.dx * cell,
          top: p.dy * cell,
          width: cell,
          height: cell,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: Colors.black26, width: 0.5),
            ),
            padding: const EdgeInsets.all(1),
            child: Stack(
              children: [
                Text('$n',
                    style: TextStyle(
                        fontSize: cell * 0.28,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600)),
                if (_ladders.containsKey(n))
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text('🪜${_ladders[n]}',
                        style: TextStyle(
                            fontSize: cell * 0.22, color: Colors.black87)),
                  ),
                if (_snakes.containsKey(n))
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text('🐍${_snakes[n]}',
                        style: TextStyle(
                            fontSize: cell * 0.22, color: Colors.black87)),
                  ),
              ],
            ),
          ),
        ));
      }

      // Lines for snakes and ladders.
      children.add(Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _LinkPainter(_ladders, _snakes, _cellPos),
          ),
        ),
      ));

      // Tokens.
      void addToken(int pos, Color color, double dx) {
        final p = pos == 0 ? const Offset(0, 10) : _cellPos(pos);
        children.add(AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          left: p.dx * cell + cell * 0.1 + dx,
          top: p.dy * cell + cell * 0.35,
          width: cell * 0.45,
          height: cell * 0.45,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ));
      }

      addToken(_you, Colors.blue, 0);
      addToken(_ai, Colors.red, cell * 0.35);

      return SizedBox(
        width: size,
        height: size,
        child: Stack(children: children),
      );
    });
  }
}

class _LinkPainter extends CustomPainter {
  final Map<int, int> ladders;
  final Map<int, int> snakes;
  final Offset Function(int) pos;

  _LinkPainter(this.ladders, this.snakes, this.pos);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 10;
    Offset center(int n) {
      final p = pos(n);
      return Offset((p.dx + 0.5) * cell, (p.dy + 0.5) * cell);
    }

    final lp = Paint()
      ..color = Colors.brown
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    ladders.forEach((from, to) {
      final a = center(from);
      final b = center(to);
      final d = b - a;
      final len = d.distance;
      if (len == 0) return;
      final nrm = Offset(-d.dy / len, d.dx / len) * (cell * 0.12);
      canvas.drawLine(a + nrm, b + nrm, lp);
      canvas.drawLine(a - nrm, b - nrm, lp);
      final rungs = (len / (cell * 0.5)).floor();
      for (int i = 1; i < rungs; i++) {
        final t = i / rungs;
        final m = Offset.lerp(a, b, t)!;
        canvas.drawLine(m + nrm, m - nrm, lp..strokeWidth = 2.5);
      }
      lp.strokeWidth = 4;
    });

    final sp = Paint()
      ..color = Colors.green.shade800
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    snakes.forEach((from, to) {
      final a = center(from);
      final b = center(to);
      final d = b - a;
      final len = d.distance;
      if (len == 0) return;
      final nrm = Offset(-d.dy / len, d.dx / len) * (cell * 0.6);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(
          a.dx + d.dx * 0.25 + nrm.dx,
          a.dy + d.dy * 0.25 + nrm.dy,
          a.dx + d.dx * 0.75 - nrm.dx,
          a.dy + d.dy * 0.75 - nrm.dy,
          b.dx,
          b.dy,
        );
      canvas.drawPath(path, sp);
      canvas.drawCircle(a, cell * 0.14, Paint()..color = Colors.red.shade900);
    });
  }

  @override
  bool shouldRepaint(covariant _LinkPainter oldDelegate) => false;
}
