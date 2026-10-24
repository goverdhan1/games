import 'dart:math';

import 'package:flutter/material.dart';

/// Sky Dash: endless tap-to-flap flyer. Tap anywhere to flap, avoid the pipes.
class FlyerScreen extends StatefulWidget {
  const FlyerScreen({super.key});

  @override
  State<FlyerScreen> createState() => _FlyerScreenState();
}

class _Pipe {
  double x; // left edge in px
  final double gapCenter; // fraction of height
  bool passed = false;
  _Pipe(this.x, this.gapCenter);
}

enum _Phase { ready, playing, dead }

class _FlyerScreenState extends State<FlyerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final Stopwatch _clock = Stopwatch();
  final Random _rng = Random();

  Size _size = Size.zero;
  _Phase _phase = _Phase.ready;
  double _birdY = 0; // px
  double _vel = 0; // px/s
  double _lastT = 0;
  double _bob = 0;
  double _groundScroll = 0;
  double _tilt = 0;
  final List<_Pipe> _pipes = [];
  int _score = 0;
  int _best = 0;

  // Tunables (all expressed relative to screen height H)
  static const double _gravityK = 2.3;
  static const double _flapK = -0.72;
  static const double _speedK = 0.34;
  static const double _gapK = 0.27;
  static const double _pipeWK = 0.12;
  static const double _spacingK = 0.72;
  static const double _groundK = 0.10;
  static const double _radiusK = 0.032;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..forward();
    _clock.start();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _resetRound() {
    _phase = _Phase.ready;
    _score = 0;
    _pipes.clear();
    _vel = 0;
    _tilt = 0;
    if (_size != Size.zero) _birdY = _size.height * 0.45;
  }

  void _flap() {
    if (_size == Size.zero) return;
    setState(() {
      switch (_phase) {
        case _Phase.ready:
          _phase = _Phase.playing;
          _vel = _flapK * _size.height;
          _spawnPipe(_size.width + _size.height * 0.2);
          break;
        case _Phase.playing:
          _vel = _flapK * _size.height;
          break;
        case _Phase.dead:
          _resetRound();
          break;
      }
    });
  }

  void _spawnPipe(double x) {
    final gap = _gapK;
    final margin = 0.06 + gap / 2;
    final maxCenter = 1 - _groundK - 0.06 - gap / 2;
    final center = margin + _rng.nextDouble() * (maxCenter - margin);
    _pipes.add(_Pipe(x, center));
  }

  void _tick() {
    final now = _clock.elapsedMicroseconds / 1e6;
    var dt = now - _lastT;
    _lastT = now;
    if (dt <= 0) return;
    if (dt > 0.04) dt = 0.04;
    if (_size == Size.zero) return;
    final h = _size.height;
    final w = _size.width;

    if (_birdY == 0) _birdY = h * 0.45;

    setState(() {
      if (_phase == _Phase.ready) {
        _bob += dt * 4;
        _birdY = h * 0.45 + sin(_bob) * h * 0.012;
        _groundScroll = (_groundScroll + dt * _speedK * h * 0.5) % 40;
        return;
      }
      if (_phase == _Phase.dead) {
        // fall to the ground
        final groundTop = h * (1 - _groundK) - _radiusK * h;
        if (_birdY < groundTop) {
          _vel += _gravityK * h * dt;
          _birdY = min(groundTop, _birdY + _vel * dt);
          _tilt = min(1.4, _tilt + dt * 4);
        }
        return;
      }

      // playing
      _vel += _gravityK * h * dt;
      _vel = min(_vel, 1.3 * h);
      _birdY += _vel * dt;
      _tilt = (_vel / (1.0 * h)).clamp(-0.5, 1.2);
      final speed = _speedK * h;
      _groundScroll = (_groundScroll + dt * speed) % 40;

      for (final p in _pipes) {
        p.x -= speed * dt;
      }
      _pipes.removeWhere((p) => p.x + _pipeWK * h < -10);
      if (_pipes.isEmpty || _pipes.last.x < w - _spacingK * h) {
        _spawnPipe(w + 10);
      }

      final bx = w * 0.3;
      final r = _radiusK * h;
      for (final p in _pipes) {
        final pw = _pipeWK * h;
        if (!p.passed && p.x + pw < bx - r) {
          p.passed = true;
          _score++;
          if (_score > _best) _best = _score;
        }
        // collision
        final gapTop = (p.gapCenter - _gapK / 2) * h;
        final gapBottom = (p.gapCenter + _gapK / 2) * h;
        if (bx + r * 0.85 > p.x && bx - r * 0.85 < p.x + pw) {
          if (_birdY - r * 0.85 < gapTop || _birdY + r * 0.85 > gapBottom) {
            _die();
            return;
          }
        }
      }
      if (_birdY + r > h * (1 - _groundK) || _birdY - r < -h * 0.1) {
        _die();
      }
    });
  }

  void _die() {
    _phase = _Phase.dead;
    _vel = max(_vel, 0);
    if (_score > _best) _best = _score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sky Dash'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Best: $_best'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, cons) {
          final newSize = Size(cons.maxWidth, cons.maxHeight);
          if (newSize != _size) {
            final first = _size == Size.zero;
            _size = newSize;
            if (first || _phase == _Phase.ready) _birdY = newSize.height * 0.45;
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _flap(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _FlyerPainter(
                    size: _size,
                    birdY: _birdY,
                    tilt: _tilt,
                    pipes: List.of(_pipes),
                    groundScroll: _groundScroll,
                    gapK: _gapK,
                    pipeWK: _pipeWK,
                    groundK: _groundK,
                    radiusK: _radiusK,
                  ),
                ),
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
                  ),
                ),
                if (_phase == _Phase.ready)
                  const Center(
                    child: Text(
                      'TAP TO FLAP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
                  ),
                if (_phase == _Phase.dead)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(170),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Game Over',
                              style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Score: $_score   Best: $_best',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.white70)),
                          const SizedBox(height: 12),
                          const Text('Tap to play again',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FlyerPainter extends CustomPainter {
  final Size size;
  final double birdY;
  final double tilt;
  final List<_Pipe> pipes;
  final double groundScroll;
  final double gapK, pipeWK, groundK, radiusK;

  _FlyerPainter({
    required this.size,
    required this.birdY,
    required this.tilt,
    required this.pipes,
    required this.groundScroll,
    required this.gapK,
    required this.pipeWK,
    required this.groundK,
    required this.radiusK,
  });

  @override
  void paint(Canvas canvas, Size _) {
    final w = size.width, h = size.height;
    // sky
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC)],
        ).createShader(skyRect),
    );
    // clouds (static decoration)
    final cloud = Paint()..color = Colors.white.withAlpha(150);
    for (var i = 0; i < 4; i++) {
      final cx = w * (0.12 + i * 0.27);
      final cy = h * (0.15 + (i % 2) * 0.12);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: h * 0.16, height: h * 0.05), cloud);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + h * 0.05, cy - h * 0.02), width: h * 0.1, height: h * 0.05), cloud);
    }

    // pipes
    final pipeFill = Paint()..color = const Color(0xFF43A047);
    final pipeDark = Paint()..color = const Color(0xFF2E7D32);
    final pw = pipeWK * h;
    final groundTop = h * (1 - groundK);
    for (final p in pipes) {
      final gapTop = (p.gapCenter - gapK / 2) * h;
      final gapBottom = (p.gapCenter + gapK / 2) * h;
      final capH = h * 0.035;
      final capExtra = pw * 0.08;
      // top pipe
      canvas.drawRect(Rect.fromLTWH(p.x, 0, pw, gapTop), pipeFill);
      canvas.drawRect(
          Rect.fromLTWH(p.x - capExtra, gapTop - capH, pw + capExtra * 2, capH), pipeDark);
      // bottom pipe
      canvas.drawRect(Rect.fromLTWH(p.x, gapBottom, pw, groundTop - gapBottom), pipeFill);
      canvas.drawRect(
          Rect.fromLTWH(p.x - capExtra, gapBottom, pw + capExtra * 2, capH), pipeDark);
    }

    // ground
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, w, h - groundTop),
      Paint()..color = const Color(0xFFDEB887),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, w, h * 0.015),
      Paint()..color = const Color(0xFF7CB342),
    );
    final stripe = Paint()..color = const Color(0xFFC9A26B);
    for (var x = -40 + groundScroll * -1; x < w + 40; x += 40) {
      canvas.drawRect(
          Rect.fromLTWH(x, groundTop + h * 0.03, 20, h * 0.02), stripe);
    }

    // bird
    final bx = w * 0.3;
    final r = radiusK * h;
    canvas.save();
    canvas.translate(bx, birdY);
    canvas.rotate(tilt * 0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2.3, height: r * 1.8),
      Paint()..color = const Color(0xFFFFCA28),
    );
    // wing
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-r * 0.4, r * 0.15), width: r * 1.1, height: r * 0.7),
      Paint()..color = const Color(0xFFFFA000),
    );
    // eye
    canvas.drawCircle(Offset(r * 0.55, -r * 0.3), r * 0.38, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(r * 0.67, -r * 0.3), r * 0.17, Paint()..color = Colors.black);
    // beak
    final beak = Path()
      ..moveTo(r * 0.9, -r * 0.05)
      ..lineTo(r * 1.6, r * 0.15)
      ..lineTo(r * 0.9, r * 0.4)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFF7043));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlyerPainter old) => true;
}
