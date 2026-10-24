import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  static const List<List<int>> _lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  final Random _rng = Random();
  Timer? _timer;

  List<String> _board = List.filled(9, '');
  bool _humanTurn = true;
  String? _winner; // 'X', 'O', 'draw'
  List<int> _winLine = [];
  int _wins = 0, _losses = 0, _draws = 0;
  bool _hard = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _board = List.filled(9, '');
      _humanTurn = true;
      _winner = null;
      _winLine = [];
    });
  }

  List<int>? _lineWinner(List<String> b, String p) {
    for (final l in _lines) {
      if (b[l[0]] == p && b[l[1]] == p && b[l[2]] == p) return l;
    }
    return null;
  }

  void _checkEnd() {
    final x = _lineWinner(_board, 'X');
    final o = _lineWinner(_board, 'O');
    if (x != null) {
      _winner = 'X';
      _winLine = x;
      _wins++;
    } else if (o != null) {
      _winner = 'O';
      _winLine = o;
      _losses++;
    } else if (!_board.contains('')) {
      _winner = 'draw';
      _draws++;
    }
  }

  void _tap(int i) {
    if (!_humanTurn || _winner != null || _board[i] != '') return;
    setState(() {
      _board[i] = 'X';
      _checkEnd();
      _humanTurn = false;
    });
    if (_winner == null) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 400), () {
        if (!mounted || _winner != null) return;
        setState(() {
          final m = _aiMove();
          if (m >= 0) _board[m] = 'O';
          _checkEnd();
          _humanTurn = true;
        });
      });
    }
  }

  int _aiMove() {
    final empty = [for (int i = 0; i < 9; i++) if (_board[i] == '') i];
    if (empty.isEmpty) return -1;
    if (!_hard && _rng.nextInt(100) < 35) {
      return empty[_rng.nextInt(empty.length)];
    }
    int best = -100;
    final bestMoves = <int>[];
    for (final m in empty) {
      _board[m] = 'O';
      final s = _minimax(_board, false, 0);
      _board[m] = '';
      if (s > best) {
        best = s;
        bestMoves
          ..clear()
          ..add(m);
      } else if (s == best) {
        bestMoves.add(m);
      }
    }
    return bestMoves[_rng.nextInt(bestMoves.length)];
  }

  int _minimax(List<String> b, bool aiTurn, int depth) {
    if (_lineWinner(b, 'O') != null) return 10 - depth;
    if (_lineWinner(b, 'X') != null) return depth - 10;
    if (!b.contains('')) return 0;
    int best = aiTurn ? -100 : 100;
    for (int i = 0; i < 9; i++) {
      if (b[i] != '') continue;
      b[i] = aiTurn ? 'O' : 'X';
      final s = _minimax(b, !aiTurn, depth + 1);
      b[i] = '';
      best = aiTurn ? max(best, s) : min(best, s);
    }
    return best;
  }

  String get _status {
    switch (_winner) {
      case 'X':
        return 'You win! 🎉';
      case 'O':
        return 'AI wins!';
      case 'draw':
        return "It's a draw.";
      default:
        return _humanTurn ? 'Your turn (X)' : 'AI is thinking...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh),
            onPressed: _restart,
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
                Text('You (X): $_wins   AI (O): $_losses   Draws: $_draws',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(_status, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, i) {
                        final v = _board[i];
                        final win = _winLine.contains(i);
                        return GestureDetector(
                          onTap: () => _tap(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: win
                                  ? Colors.amber.shade300
                                  : Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.indigo.shade300, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              v,
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: v == 'X'
                                    ? Colors.blue.shade700
                                    : Colors.red.shade600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Hard AI'),
                    Switch(
                      value: _hard,
                      onChanged: (v) => setState(() => _hard = v),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _restart,
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
}
