import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'board_geometry.dart';
import 'game_controller.dart';
import 'models.dart';

class BoardPainter extends CustomPainter {
  final GameController game;
  final Set<int> highlightTokenIds;
  final PlayerColor? highlightColor;

  BoardPainter({
    required this.game,
    this.highlightTokenIds = const {},
    this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / BoardGeometry.size;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFAF6E9),
    );

    _drawHome(canvas, cell, 0, 0, PlayerColor.green);
    _drawHome(canvas, cell, 9, 0, PlayerColor.yellow);
    _drawHome(canvas, cell, 0, 9, PlayerColor.red);
    _drawHome(canvas, cell, 9, 9, PlayerColor.blue);

    for (var i = 0; i < BoardGeometry.mainPath.length; i++) {
      final p = BoardGeometry.mainPath[i];
      final rect = Rect.fromLTWH(p.dx * cell, p.dy * cell, cell, cell);
      canvas.drawRect(rect, Paint()..color = Colors.white);
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFFBDBDBD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      if (BoardGeometry.safeGlobalIndices.contains(i)) {
        _drawStar(canvas, rect.center, cell * 0.28, const Color(0xFFFFA726));
      }
    }

    for (final color in PlayerColor.values) {
      final start = BoardGeometry.mainPath[color.startIndex];
      final rect = Rect.fromLTWH(start.dx * cell, start.dy * cell, cell, cell);
      canvas.drawRect(rect, Paint()..color = color.color.withValues(alpha: 0.55));
    }

    for (final color in PlayerColor.values) {
      for (final p in BoardGeometry.homeStretch[color]!) {
        final rect = Rect.fromLTWH(p.dx * cell, p.dy * cell, cell, cell);
        canvas.drawRect(rect, Paint()..color = color.color.withValues(alpha: 0.7));
        canvas.drawRect(
          rect,
          Paint()
            ..color = color.darkColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }
    }

    final cx = 7.5 * cell;
    final cy = 7.5 * cell;
    _drawCenterWedge(canvas, PlayerColor.red, [
      Offset(6 * cell, 9 * cell),
      Offset(9 * cell, 9 * cell),
      Offset(cx, cy),
    ]);
    _drawCenterWedge(canvas, PlayerColor.green, [
      Offset(6 * cell, 6 * cell),
      Offset(6 * cell, 9 * cell),
      Offset(cx, cy),
    ]);
    _drawCenterWedge(canvas, PlayerColor.yellow, [
      Offset(6 * cell, 6 * cell),
      Offset(9 * cell, 6 * cell),
      Offset(cx, cy),
    ]);
    _drawCenterWedge(canvas, PlayerColor.blue, [
      Offset(9 * cell, 6 * cell),
      Offset(9 * cell, 9 * cell),
      Offset(cx, cy),
    ]);

    for (final player in game.players) {
      for (final token in player.tokens) {
        final pos = BoardGeometry.cellForToken(token);
        final point = token.inYard
            ? Offset(pos.dx * cell, pos.dy * cell)
            : Offset((pos.dx + 0.5) * cell, (pos.dy + 0.5) * cell);
        final highlight = highlightColor == player.color &&
            highlightTokenIds.contains(token.id);
        _drawToken(canvas, point, cell * 0.36, player.color, highlight);
      }
    }
  }

  void _drawHome(
    Canvas canvas,
    double cell,
    double col,
    double row,
    PlayerColor color,
  ) {
    final outer = Rect.fromLTWH(col * cell, row * cell, 6 * cell, 6 * cell);
    canvas.drawRect(outer, Paint()..color = color.color);
    final inner = Rect.fromLTWH(
      (col + 1) * cell,
      (row + 1) * cell,
      4 * cell,
      4 * cell,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(cell * 0.3)),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    for (final slot in BoardGeometry.yardSlots[color]!) {
      canvas.drawCircle(
        Offset(slot.dx * cell, slot.dy * cell),
        cell * 0.42,
        Paint()
          ..color = color.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawCenterWedge(Canvas canvas, PlayerColor color, List<Offset> pts) {
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color.color.withValues(alpha: 0.85));
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * 4 * math.pi / 5;
      final p = Offset(c.dx + r * math.cos(angle), c.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawToken(
    Canvas canvas,
    Offset center,
    double radius,
    PlayerColor color,
    bool highlight,
  ) {
    if (highlight) {
      canvas.drawCircle(
        center,
        radius * 1.35,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        center,
        radius * 1.35,
        Paint()
          ..color = color.darkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = color.darkColor);
    canvas.drawCircle(center, radius * 0.78, Paint()..color = color.color);
    canvas.drawCircle(
      center.translate(-radius * 0.2, -radius * 0.25),
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}
