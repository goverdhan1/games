import 'dart:math';

import 'package:flutter/material.dart';

/// Hardcoded multiple-choice trivia quiz (10 random questions per round).
class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _Question {
  final String category;
  final String text;
  final List<String> options;
  final int answer; // index into options
  const _Question(this.category, this.text, this.options, this.answer);
}

class _TriviaScreenState extends State<TriviaScreen> {
  static const List<_Question> _bank = [
    _Question('Geography', 'What is the capital of Australia?',
        ['Sydney', 'Melbourne', 'Canberra', 'Perth'], 2),
    _Question('Science', 'Which planet is known as the Red Planet?',
        ['Venus', 'Mars', 'Jupiter', 'Mercury'], 1),
    _Question('Science', 'What is the chemical symbol for gold?',
        ['Ag', 'Gd', 'Go', 'Au'], 3),
    _Question('History', 'In which year did World War II end?',
        ['1943', '1945', '1947', '1950'], 1),
    _Question('Geography', 'Which is the longest river in the world (commonly cited)?',
        ['Amazon', 'Yangtze', 'Mississippi', 'Nile'], 3),
    _Question('Art', 'Who painted the Mona Lisa?',
        ['Michelangelo', 'Leonardo da Vinci', 'Raphael', 'Van Gogh'], 1),
    _Question('Science', 'How many bones are in the adult human body?',
        ['186', '206', '226', '246'], 1),
    _Question('Geography', 'Which is the largest ocean on Earth?',
        ['Atlantic', 'Indian', 'Arctic', 'Pacific'], 3),
    _Question('Literature', 'Who wrote "Romeo and Juliet"?',
        ['Charles Dickens', 'William Shakespeare', 'Mark Twain', 'Jane Austen'], 1),
    _Question('Math', 'What is the value of pi to two decimal places?',
        ['3.12', '3.14', '3.16', '3.18'], 1),
    _Question('Technology', 'What does "CPU" stand for?',
        ['Central Processing Unit', 'Computer Personal Unit',
         'Central Program Utility', 'Core Processing Update'], 0),
    _Question('Nature', 'Which animal is the largest mammal?',
        ['African Elephant', 'Blue Whale', 'Giraffe', 'Hippopotamus'], 1),
    _Question('Geography', 'Mount Everest lies on the border of Nepal and which country?',
        ['India', 'Bhutan', 'China (Tibet)', 'Pakistan'], 2),
    _Question('Science', 'What gas do plants absorb from the atmosphere?',
        ['Oxygen', 'Nitrogen', 'Carbon dioxide', 'Hydrogen'], 2),
    _Question('Sports', 'How many players are on a soccer team on the field?',
        ['9', '10', '11', '12'], 2),
    _Question('History', 'Who was the first President of the United States?',
        ['Thomas Jefferson', 'George Washington', 'Abraham Lincoln', 'John Adams'], 1),
    _Question('Science', 'What is the hardest natural substance?',
        ['Gold', 'Iron', 'Quartz', 'Diamond'], 3),
    _Question('Food', 'Which country is the origin of sushi?',
        ['China', 'Korea', 'Japan', 'Thailand'], 2),
    _Question('Space', 'What is the closest star to Earth?',
        ['Proxima Centauri', 'Sirius', 'The Sun', 'Alpha Centauri A'], 2),
    _Question('Math', 'What is 12 x 12?',
        ['124', '132', '144', '156'], 2),
  ];

  static const int _roundSize = 10;

  final Random _rng = Random();
  late List<_Question> _round;
  late List<List<int>> _order; // shuffled option indices per question
  int _index = 0;
  int _score = 0;
  int? _picked; // position tapped within displayed order
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final all = List<_Question>.from(_bank)..shuffle(_rng);
    _round = all.take(_roundSize).toList();
    _order = _round
        .map((q) => List<int>.generate(q.options.length, (i) => i)..shuffle(_rng))
        .toList();
    _index = 0;
    _score = 0;
    _picked = null;
    _finished = false;
  }

  void _pick(int pos) {
    if (_picked != null) return;
    final q = _round[_index];
    setState(() {
      _picked = pos;
      if (_order[_index][pos] == q.answer) _score++;
    });
  }

  void _next() {
    setState(() {
      if (_index + 1 >= _round.length) {
        _finished = true;
      } else {
        _index++;
        _picked = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia'),
        actions: [
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_start),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _finished ? _result(context) : _question(context),
        ),
      ),
    );
  }

  Widget _question(BuildContext context) {
    final q = _round[_index];
    final order = _order[_index];
    final answered = _picked != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Question ${_index + 1}/${_round.length}'),
            Text('Score: $_score',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (_index + (answered ? 1 : 0)) / _round.length),
        const SizedBox(height: 20),
        Center(child: Chip(label: Text(q.category))),
        const SizedBox(height: 12),
        Text(
          q.text,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: order.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, pos) {
              final isCorrect = order[pos] == q.answer;
              final isPicked = _picked == pos;
              Color? bg;
              Color? fg;
              IconData? icon;
              if (answered) {
                if (isCorrect) {
                  bg = Colors.green.shade600;
                  fg = Colors.white;
                  icon = Icons.check_circle;
                } else if (isPicked) {
                  bg = Colors.red.shade600;
                  fg = Colors.white;
                  icon = Icons.cancel;
                }
              }
              return SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg,
                    foregroundColor: fg,
                    disabledBackgroundColor: bg,
                    disabledForegroundColor: fg,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: answered ? null : () => _pick(pos),
                  child: Row(
                    children: [
                      Text('${String.fromCharCode(65 + pos)}.  ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(q.options[order[pos]],
                            style: const TextStyle(fontSize: 16)),
                      ),
                      if (icon != null) Icon(icon, color: Colors.white),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (answered)
          FilledButton(
            onPressed: _next,
            child: Text(_index + 1 >= _round.length ? 'See results' : 'Next question'),
          ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final pct = (_score / _round.length * 100).round();
    String msg;
    if (pct == 100) {
      msg = 'Perfect! Trivia master!';
    } else if (pct >= 70) {
      msg = 'Great job!';
    } else if (pct >= 40) {
      msg = 'Not bad - try again!';
    } else {
      msg = 'Keep practicing!';
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 90, color: Colors.amber),
          const SizedBox(height: 12),
          Text('$_score / ${_round.length}',
              style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(msg, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => setState(_start),
            icon: const Icon(Icons.replay),
            label: const Text('Play again'),
          ),
        ],
      ),
    );
  }
}
