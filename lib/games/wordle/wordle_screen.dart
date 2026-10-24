import 'dart:math';

import 'package:flutter/material.dart';

/// Word Quest: guess the hidden 5-letter word in 6 tries.
/// Green = right letter, right spot. Yellow = right letter, wrong spot.
/// Gray = letter not in the word.
class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

enum _LetterState { unknown, absent, present, correct }

class _WordleScreenState extends State<WordleScreen> {
  static const int _len = 5;
  static const int _tries = 6;

  static const List<String> _words = [
    'APPLE', 'BRAVE', 'CRANE', 'DREAM', 'EAGLE', 'FLAME', 'GRAPE', 'HOUSE',
    'IVORY', 'JOKER', 'KNIFE', 'LEMON', 'MANGO', 'NIGHT', 'OCEAN', 'PIANO',
    'QUEEN', 'RIVER', 'STONE', 'TIGER', 'UNITY', 'VIVID', 'WATER', 'YOUTH',
    'ZEBRA', 'BEACH', 'CLOUD', 'DANCE', 'EARTH', 'FROST', 'GHOST', 'HEART',
    'INDEX', 'JELLY', 'KARMA', 'LIGHT', 'MUSIC', 'NOBLE', 'OLIVE', 'PLANT',
    'QUIET', 'ROBOT', 'SMILE', 'TRAIN', 'URBAN', 'VOICE', 'WHEAT', 'XENON',
    'YEAST', 'ZESTY', 'ALARM', 'BLAZE', 'CHAIR', 'DRIVE', 'EMBER', 'FAITH',
    'GLOBE', 'HAPPY', 'IMAGE', 'JUICE', 'KIOSK', 'LUNAR', 'MAGIC', 'NURSE',
    'ORBIT', 'PEARL', 'QUEST', 'RADIO', 'SHARK', 'TABLE', 'UNDER', 'VALUE',
    'WORLD', 'YIELD', 'ZONAL', 'BRICK', 'CANDY', 'DAISY', 'ENTRY', 'FLOUR',
    'GIANT', 'HONEY', 'INPUT', 'JEWEL', 'KAYAK', 'LASER', 'MAPLE', 'NERVE',
    'OPERA', 'PRIZE', 'QUOTE', 'RAINY', 'SUGAR', 'TOAST', 'UMBRA', 'VAPOR',
    'WHALE', 'PIXEL', 'SPICE', 'THUMB', 'GRASS', 'PLUMB', 'CLOCK', 'BLOOM',
  ];

  final Random _rng = Random();
  late String _answer;
  List<String> _guesses = [];
  String _current = '';
  bool _won = false;
  bool _lost = false;
  String _message = '';
  final Map<String, _LetterState> _keyStates = {};

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _answer = _words[_rng.nextInt(_words.length)];
    _guesses = [];
    _current = '';
    _won = false;
    _lost = false;
    _message = '';
    _keyStates.clear();
  }

  bool get _over => _won || _lost;

  List<_LetterState> _evaluate(String guess) {
    final res = List.filled(_len, _LetterState.absent);
    final remaining = <String, int>{};
    for (var i = 0; i < _len; i++) {
      if (guess[i] == _answer[i]) {
        res[i] = _LetterState.correct;
      } else {
        remaining[_answer[i]] = (remaining[_answer[i]] ?? 0) + 1;
      }
    }
    for (var i = 0; i < _len; i++) {
      if (res[i] == _LetterState.correct) continue;
      final n = remaining[guess[i]] ?? 0;
      if (n > 0) {
        res[i] = _LetterState.present;
        remaining[guess[i]] = n - 1;
      }
    }
    return res;
  }

  void _type(String letter) {
    if (_over || _current.length >= _len) return;
    setState(() {
      _current += letter;
      _message = '';
    });
  }

  void _backspace() {
    if (_over || _current.isEmpty) return;
    setState(() {
      _current = _current.substring(0, _current.length - 1);
      _message = '';
    });
  }

  void _submit() {
    if (_over) return;
    if (_current.length < _len) {
      setState(() => _message = 'Not enough letters');
      return;
    }
    final guess = _current;
    final states = _evaluate(guess);
    setState(() {
      _guesses.add(guess);
      _current = '';
      for (var i = 0; i < _len; i++) {
        final old = _keyStates[guess[i]] ?? _LetterState.unknown;
        if (states[i].index > old.index) _keyStates[guess[i]] = states[i];
      }
      if (guess == _answer) {
        _won = true;
        _message = 'Brilliant! You got it in ${_guesses.length}.';
      } else if (_guesses.length >= _tries) {
        _lost = true;
        _message = 'Out of tries! The word was $_answer.';
      } else {
        _message = '';
      }
    });
  }

  Color _color(_LetterState s) {
    switch (s) {
      case _LetterState.correct:
        return const Color(0xFF538D4E);
      case _LetterState.present:
        return const Color(0xFFB59F3B);
      case _LetterState.absent:
        return const Color(0xFF3A3A3C);
      case _LetterState.unknown:
        return const Color(0xFF818384);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121213),
      appBar: AppBar(
        title: const Text('Word Quest'),
        actions: [
          IconButton(
            tooltip: 'New word',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_newGame),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 36,
              child: Center(
                child: Text(
                  _message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            Expanded(child: Center(child: _board())),
            _keyboard(),
            if (_over)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton(
                  onPressed: () => setState(_newGame),
                  child: const Text('Play again'),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _board() {
    return LayoutBuilder(builder: (context, cons) {
      final cell = min(
        (cons.maxWidth - 32) / _len - 6,
        (cons.maxHeight - 8) / _tries - 6,
      ).clamp(24.0, 62.0);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_tries, (r) {
          final submitted = r < _guesses.length;
          final isCurrent = r == _guesses.length && !_over;
          final text = submitted ? _guesses[r] : (isCurrent ? _current : '');
          final states = submitted ? _evaluate(_guesses[r]) : null;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_len, (c) {
              final letter = c < text.length ? text[c] : '';
              Color bg = Colors.transparent;
              Color border = const Color(0xFF3A3A3C);
              if (states != null) {
                bg = _color(states[c]);
                border = bg;
              } else if (letter.isNotEmpty) {
                border = const Color(0xFF818384);
              }
              return Container(
                width: cell,
                height: cell,
                margin: const EdgeInsets.all(3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: border, width: 2),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: cell * 0.55,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          );
        }),
      );
    });
  }

  Widget _keyboard() {
    const rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (i == 2) _wideKey('ENTER', _submit),
                for (final ch in rows[i].split('')) _letterKey(ch),
                if (i == 2) _wideKey('⌫', _backspace),
              ],
            ),
        ],
      ),
    );
  }

  Widget _letterKey(String ch) {
    final state = _keyStates[ch] ?? _LetterState.unknown;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        width: 32,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: _color(state),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () => _type(ch),
          child: Text(ch, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _wideKey(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        width: 52,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: const Color(0xFF818384),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
