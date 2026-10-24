import 'dart:math' as math;

import 'package:flutter/material.dart';

class DiceWidget extends StatefulWidget {
  final int? value;
  final bool enabled;
  final bool rolling;
  final VoidCallback? onTap;

  const DiceWidget({
    super.key,
    required this.value,
    required this.enabled,
    this.rolling = false,
    this.onTap,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _display = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..addListener(() {
        if (widget.rolling && _controller.isAnimating) {
          setState(() {
            _display = 1 + (_controller.value * 18).floor() % 6;
          });
        }
      });
    _display = widget.value ?? 1;
  }

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !oldWidget.rolling) {
      _controller.forward(from: 0).whenComplete(() {
        if (mounted && widget.value != null) {
          setState(() => _display = widget.value!);
        }
      });
    } else if (widget.value != null && !widget.rolling) {
      _display = widget.value!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * math.pi * 2,
            child: Opacity(
              opacity: widget.enabled || widget.value != null ? 1 : 0.55,
              child: child,
            ),
          );
        },
        child: _DiceFace(value: _display, glow: widget.enabled),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  final int value;
  final bool glow;

  const _DiceFace({required this.value, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5D4037), width: 2),
        boxShadow: [
          BoxShadow(
            color: glow
                ? const Color(0xFFFF8A65).withValues(alpha: 0.55)
                : Colors.black26,
            blurRadius: glow ? 12 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(painter: _PipPainter(value.clamp(1, 6))),
    );
  }
}

class _PipPainter extends CustomPainter {
  final int value;
  _PipPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF3E2723);
    for (final p in _pips(value, size)) {
      canvas.drawCircle(p, size.shortestSide * 0.08, paint);
    }
  }

  List<Offset> _pips(int v, Size s) {
    Offset c(double x, double y) => Offset(s.width * x, s.height * y);
    switch (v) {
      case 1:
        return [c(0.5, 0.5)];
      case 2:
        return [c(0.28, 0.28), c(0.72, 0.72)];
      case 3:
        return [c(0.28, 0.28), c(0.5, 0.5), c(0.72, 0.72)];
      case 4:
        return [c(0.28, 0.28), c(0.72, 0.28), c(0.28, 0.72), c(0.72, 0.72)];
      case 5:
        return [
          c(0.28, 0.28),
          c(0.72, 0.28),
          c(0.5, 0.5),
          c(0.28, 0.72),
          c(0.72, 0.72),
        ];
      default:
        return [
          c(0.28, 0.25),
          c(0.72, 0.25),
          c(0.28, 0.5),
          c(0.72, 0.5),
          c(0.28, 0.75),
          c(0.72, 0.75),
        ];
    }
  }

  @override
  bool shouldRepaint(covariant _PipPainter oldDelegate) =>
      oldDelegate.value != value;
}
