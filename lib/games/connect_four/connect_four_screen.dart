import 'dart:math';

import 'package:flutter/material.dart';

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  static const rows = 6;
  static const cols = 7;
  late List<List<int>> board; // 0 empty, 1 human, 2 ai
  bool humanTurn = true;
  String status = 'Your turn (Red)';
  bool gameOver = false;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    board = List.generate(rows, (_) => List.filled(cols, 0));
    humanTurn = true;
    status = 'Your turn (Red)';
    gameOver = false;
    setState(() {});
  }

  int? _dropRow(int col, List<List<int>> b) {
    for (var r = rows - 1; r >= 0; r--) {
      if (b[r][col] == 0) return r;
    }
    return null;
  }

  bool _wins(List<List<int>> b, int p) {
    bool line(int r, int c, int dr, int dc) {
      for (var i = 0; i < 4; i++) {
        final rr = r + dr * i, cc = c + dc * i;
        if (rr < 0 || rr >= rows || cc < 0 || cc >= cols || b[rr][cc] != p) {
          return false;
        }
      }
      return true;
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (line(r, c, 0, 1) ||
            line(r, c, 1, 0) ||
            line(r, c, 1, 1) ||
            line(r, c, 1, -1)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _full(List<List<int>> b) =>
      b.every((row) => row.every((c) => c != 0));

  void _play(int col) {
    if (gameOver || !humanTurn) return;
    final r = _dropRow(col, board);
    if (r == null) return;
    setState(() {
      board[r][col] = 1;
      if (_wins(board, 1)) {
        status = 'You win!';
        gameOver = true;
        return;
      }
      if (_full(board)) {
        status = 'Draw';
        gameOver = true;
        return;
      }
      humanTurn = false;
      status = 'AI thinking…';
    });
    Future<void>.delayed(const Duration(milliseconds: 400), _aiMove);
  }

  void _aiMove() {
    if (!mounted || gameOver) return;
    // Prefer winning / blocking else random
    int? pick;
    for (final p in [2, 1]) {
      for (var c = 0; c < cols; c++) {
        final copy = board.map((r) => List<int>.from(r)).toList();
        final r = _dropRow(c, copy);
        if (r == null) continue;
        copy[r][c] = p;
        if (_wins(copy, p)) {
          pick = c;
          break;
        }
      }
      if (pick != null) break;
    }
    if (pick == null) {
      final options = List.generate(cols, (i) => i)
          .where((c) => _dropRow(c, board) != null)
          .toList()
        ..shuffle(_rng);
      pick = options.first;
    }
    final col = pick;
    final r = _dropRow(col, board)!;
    setState(() {
      board[r][col] = 2;
      if (_wins(board, 2)) {
        status = 'AI wins!';
        gameOver = true;
      } else if (_full(board)) {
        status = 'Draw';
        gameOver = true;
      } else {
        humanTurn = true;
        status = 'Your turn (Red)';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Four'),
        backgroundColor: const Color(0xFFF9A825),
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(status, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: cols / rows,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: List.generate(rows, (r) {
                      return Expanded(
                        child: Row(
                          children: List.generate(cols, (c) {
                            final v = board[r][c];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _play(c),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: v == 0
                                        ? Colors.white
                                        : v == 1
                                            ? Colors.red
                                            : Colors.amber,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
