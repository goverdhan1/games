import 'dart:math';

import 'package:flutter/material.dart';

class ColorCardsScreen extends StatefulWidget {
  const ColorCardsScreen({super.key});

  @override
  State<ColorCardsScreen> createState() => _ColorCardsScreenState();
}

class _Card {
  final int color; // 0-3
  final int rank; // 0-9
  _Card(this.color, this.rank);
  static const colors = [Colors.red, Colors.blue, Colors.green, Colors.orange];
}

class _ColorCardsScreenState extends State<ColorCardsScreen> {
  late List<_Card> deck;
  late List<_Card> you;
  late List<_Card> ai;
  late _Card top;
  final _rng = Random();
  String status = 'Match color or number';

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    deck = [for (var c = 0; c < 4; c++) for (var r = 0; r < 10; r++) _Card(c, r)]..shuffle(_rng);
    you = deck.sublist(0, 7);
    ai = deck.sublist(7, 14);
    deck = deck.sublist(14);
    top = deck.removeLast();
    status = 'Your turn — match color or number';
    setState(() {});
  }

  bool _canPlay(_Card c) => c.color == top.color || c.rank == top.rank;

  void _play(int i) {
    final c = you[i];
    if (!_canPlay(c)) return;
    you.removeAt(i);
    top = c;
    if (you.isEmpty) {
      status = 'You win!';
      setState(() {});
      return;
    }
    setState(() => status = 'AI turn…');
    Future<void>.delayed(const Duration(milliseconds: 500), _aiTurn);
  }

  void _draw() {
    if (deck.isEmpty) return;
    you.add(deck.removeLast());
    setState(() => status = 'AI turn…');
    Future<void>.delayed(const Duration(milliseconds: 500), _aiTurn);
  }

  void _aiTurn() {
    if (!mounted || you.isEmpty) return;
    final idx = ai.indexWhere(_canPlay);
    if (idx >= 0) {
      top = ai.removeAt(idx);
      if (ai.isEmpty) {
        setState(() => status = 'AI wins!');
        return;
      }
    } else if (deck.isNotEmpty) {
      ai.add(deck.removeLast());
    }
    setState(() => status = 'Your turn — match color or number');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Cards'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _deal, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Text('AI cards: ${ai.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            width: 72,
            height: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _Card.colors[top.color],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${top.rank}', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(status),
          const Spacer(),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: you.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = you[i];
                final ok = _canPlay(c);
                return GestureDetector(
                  onTap: ok ? () => _play(i) : null,
                  child: Opacity(
                    opacity: ok ? 1 : 0.45,
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        color: _Card.colors[c.color],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black26),
                      ),
                      alignment: Alignment.center,
                      child: Text('${c.rank}', style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(onPressed: _draw, child: const Text('Draw card')),
          ),
        ],
      ),
    );
  }
}
