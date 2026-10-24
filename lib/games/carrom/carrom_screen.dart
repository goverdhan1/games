import 'dart:math';

import 'package:flutter/material.dart';

class CarromScreen extends StatefulWidget {
  const CarromScreen({super.key});

  @override
  State<CarromScreen> createState() => _CarromScreenState();
}

class _Coin {
  Offset p;
  Offset v;
  final Color color;
  bool pocketed;
  _Coin(this.p, this.color) : v = Offset.zero, pocketed = false;
}

class _CarromScreenState extends State<CarromScreen> with SingleTickerProviderStateMixin {
  late List<_Coin> coins;
  late _Coin striker;
  int score = 0;
  Offset? dragStart;
  Offset? dragEnd;
  late AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _reset();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_step)
      ..forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _reset() {
    coins = [
      _Coin(const Offset(0.5, 0.5), Colors.black),
      _Coin(const Offset(0.42, 0.45), Colors.white),
      _Coin(const Offset(0.58, 0.45), Colors.white),
      _Coin(const Offset(0.42, 0.55), Colors.red),
      _Coin(const Offset(0.58, 0.55), Colors.red),
    ];
    striker = _Coin(const Offset(0.5, 0.85), Colors.blueGrey);
    score = 0;
    setState(() {});
  }

  void _step() {
    var moving = false;
    for (final c in [...coins, striker]) {
      if (c.pocketed) continue;
      if (c.v.distance > 0.0002) {
        moving = true;
        c.p += c.v;
        c.v *= 0.985;
        c.p = Offset(c.p.dx.clamp(0.05, 0.95), c.p.dy.clamp(0.05, 0.95));
        for (final pocket in const [Offset(0.08, 0.08), Offset(0.92, 0.08), Offset(0.08, 0.92), Offset(0.92, 0.92)]) {
          if ((c.p - pocket).distance < 0.06) {
            c.pocketed = true;
            c.v = Offset.zero;
            if (c != striker) score += c.color == Colors.black ? 5 : 2;
          }
        }
      } else {
        c.v = Offset.zero;
      }
    }
    // simple collisions
    final all = [...coins.where((c) => !c.pocketed), if (!striker.pocketed) striker];
    for (var i = 0; i < all.length; i++) {
      for (var j = i + 1; j < all.length; j++) {
        final a = all[i], b = all[j];
        final d = b.p - a.p;
        if (d.distance < 0.07 && d.distance > 0) {
          final n = d / d.distance;
          final overlap = 0.07 - d.distance;
          a.p -= n * (overlap / 2);
          b.p += n * (overlap / 2);
          final va = a.v;
          a.v = b.v;
          b.v = va;
        }
      }
    }
    if (striker.pocketed) {
      striker.pocketed = false;
      striker.p = const Offset(0.5, 0.85);
      striker.v = Offset.zero;
    }
    if (moving || true) setState(() {});
  }

  void _shoot() {
    if (dragStart == null || dragEnd == null) return;
    final dir = dragStart! - dragEnd!;
    striker.v = dir * 0.08;
    dragStart = dragEnd = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carrom Lite · $score'),
        backgroundColor: const Color(0xFF4E342E),
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _reset, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Drag back on striker (blue-grey) and release to shoot'),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final side = min(box.maxWidth, box.maxHeight) - 24;
                return Center(
                  child: GestureDetector(
                    onPanStart: (d) {
                      final local = d.localPosition;
                      final p = Offset(local.dx / side, local.dy / side);
                      if ((p - striker.p).distance < 0.1) {
                        dragStart = p;
                        dragEnd = p;
                      }
                    },
                    onPanUpdate: (d) {
                      if (dragStart == null) return;
                      dragEnd = Offset(d.localPosition.dx / side, d.localPosition.dy / side);
                      setState(() {});
                    },
                    onPanEnd: (_) => _shoot(),
                    child: Container(
                      width: side,
                      height: side,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7CCC8),
                        border: Border.all(color: const Color(0xFF5D4037), width: 8),
                      ),
                      child: CustomPaint(
                        painter: _CarromPainter(coins: coins, striker: striker, dragStart: dragStart, dragEnd: dragEnd),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CarromPainter extends CustomPainter {
  final List<_Coin> coins;
  final _Coin striker;
  final Offset? dragStart, dragEnd;
  _CarromPainter({required this.coins, required this.striker, this.dragStart, this.dragEnd});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in const [Offset(0.08, 0.08), Offset(0.92, 0.08), Offset(0.08, 0.92), Offset(0.92, 0.92)]) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), 14, Paint()..color = Colors.black87);
    }
    void drawCoin(_Coin c) {
      if (c.pocketed) return;
      canvas.drawCircle(Offset(c.p.dx * size.width, c.p.dy * size.height), size.width * 0.035, Paint()..color = c.color);
    }
    for (final c in coins) {
      drawCoin(c);
    }
    drawCoin(striker);
    if (dragStart != null && dragEnd != null) {
      canvas.drawLine(
        Offset(dragStart!.dx * size.width, dragStart!.dy * size.height),
        Offset(dragEnd!.dx * size.width, dragEnd!.dy * size.height),
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CarromPainter oldDelegate) => true;
}
