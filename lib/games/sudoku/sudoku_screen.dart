import 'dart:math';

import 'package:flutter/material.dart';

/// Sudoku with a fixed 9x9 puzzle and an on-screen number pad.
class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  static const String _puzzle =
      '530070000'
      '600195000'
      '098000060'
      '800060003'
      '400803001'
      '700020006'
      '060000280'
      '000419005'
      '000080079';

  static const String _solution =
      '534678912'
      '672195348'
      '198342567'
      '859761423'
      '426853791'
      '713924856'
      '961537284'
      '287419635'
      '345286179';

  late List<int> _cells;
  int _sel = -1;
  int _mistakes = 0;
  bool _showedWin = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _cells = _puzzle.split('').map(int.parse).toList();
    _sel = -1;
    _mistakes = 0;
    _showedWin = false;
  }

  bool _isGiven(int i) => _puzzle[i] != '0';
  int _sol(int i) => int.parse(_solution[i]);

  bool _isWrong(int i) => _cells[i] != 0 && _cells[i] != _sol(i);

  bool get _solved {
    for (var i = 0; i < 81; i++) {
      if (_cells[i] != _sol(i)) return false;
    }
    return true;
  }

  int _countOf(int n) => _cells.where((v) => v == n).length;

  void _enter(int n) {
    if (_sel < 0 || _isGiven(_sel)) return;
    setState(() {
      _cells[_sel] = n;
      if (n != 0 && n != _sol(_sel)) _mistakes++;
    });
    _checkWin();
  }

  void _hint() {
    if (_sel < 0 || _isGiven(_sel)) return;
    setState(() => _cells[_sel] = _sol(_sel));
    _checkWin();
  }

  void _checkWin() {
    if (_solved && !_showedWin) {
      _showedWin = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Solved!'),
            content: Text('Puzzle complete with $_mistakes mistake(s).'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(_reset);
                },
                child: const Text('Play again'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_reset),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Mistakes: $_mistakes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, cons) {
                    final size = min(cons.maxWidth - 16, cons.maxHeight - 8);
                    return SizedBox(
                      width: size,
                      height: size,
                      child: _grid(size),
                    );
                  },
                ),
              ),
            ),
            _pad(context),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _grid(double size) {
    final selVal = _sel >= 0 ? _cells[_sel] : 0;
    final selRow = _sel >= 0 ? _sel ~/ 9 : -1;
    final selCol = _sel >= 0 ? _sel % 9 : -1;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2.5)),
      child: Column(
        children: List.generate(9, (r) {
          return Expanded(
            child: Row(
              children: List.generate(9, (c) {
                final i = r * 9 + c;
                final v = _cells[i];
                Color bg = Colors.white;
                if (_sel >= 0) {
                  final sameBox =
                      (r ~/ 3 == selRow ~/ 3) && (c ~/ 3 == selCol ~/ 3);
                  if (r == selRow || c == selCol || sameBox) {
                    bg = const Color(0xFFE3F2FD);
                  }
                  if (selVal != 0 && v == selVal) bg = const Color(0xFFBBDEFB);
                  if (i == _sel) bg = const Color(0xFF90CAF9);
                }
                if (_isWrong(i)) bg = const Color(0xFFFFCDD2);
                final thickRight = c % 3 == 2 && c != 8;
                final thickBottom = r % 3 == 2 && r != 8;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _sel = i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border(
                          right: BorderSide(
                            color: Colors.black,
                            width: thickRight ? 2.0 : (c == 8 ? 0 : 0.5),
                          ),
                          bottom: BorderSide(
                            color: Colors.black,
                            width: thickBottom ? 2.0 : (r == 8 ? 0 : 0.5),
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: v == 0
                          ? null
                          : Text(
                              '$v',
                              style: TextStyle(
                                fontSize: size / 9 * 0.58,
                                fontWeight:
                                    _isGiven(i) ? FontWeight.bold : FontWeight.w500,
                                color: _isGiven(i)
                                    ? Colors.black
                                    : (_isWrong(i)
                                        ? Colors.red.shade700
                                        : Colors.blue.shade800),
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _pad(BuildContext context) {
    Widget numBtn(int n) {
      final done = _countOf(n) >= 9;
      return Padding(
        padding: const EdgeInsets.all(3),
        child: SizedBox(
          width: 52,
          height: 52,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: done ? null : () => _enter(n),
            child: Text('$n', style: const TextStyle(fontSize: 22)),
          ),
        ),
      );
    }

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [for (var n = 1; n <= 9; n++) numBtn(n)],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _enter(0),
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('Erase'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _hint,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Hint'),
            ),
          ],
        ),
      ],
    );
  }
}
