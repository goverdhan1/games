import 'dart:math';

import 'package:flutter/material.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  static const icons = ['🍎', '🍌', '🍇', '🍉', '🍓', '🍒', '🥝', '🍑'];
  late List<_Card> cards;
  int? first;
  int moves = 0;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final vals = [...icons, ...icons]..shuffle(Random());
    cards = List.generate(16, (i) => _Card(vals[i]));
    first = null;
    moves = 0;
    busy = false;
    setState(() {});
  }

  Future<void> _tap(int i) async {
    if (busy || cards[i].matched || cards[i].flipped) return;
    setState(() => cards[i].flipped = true);
    if (first == null) {
      first = i;
      return;
    }
    moves++;
    busy = true;
    final a = first!;
    if (cards[a].emoji == cards[i].emoji) {
      cards[a].matched = true;
      cards[i].matched = true;
      first = null;
      busy = false;
      setState(() {});
      if (cards.every((c) => c.matched)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('You won!'),
            content: Text('Matched all pairs in $moves moves.'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reset();
                },
                child: const Text('Play again'),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        cards[a].flipped = false;
        cards[i].flipped = false;
        first = null;
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory · $moves moves'),
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const Spacings(),
        itemCount: 16,
        itemBuilder: (_, i) {
          final c = cards[i];
          final show = c.flipped || c.matched;
          return GestureDetector(
            onTap: () => _tap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: show ? Colors.white : const Color(0xFF6A1B9A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              alignment: Alignment.center,
              child: Text(show ? c.emoji : '?', style: const TextStyle(fontSize: 32)),
            ),
          );
        },
      ),
    );
  }
}

class Spacings extends SliverGridDelegateWithFixedCrossAxisCount {
  const Spacings()
      : super(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10);
}

class _Card {
  final String emoji;
  bool flipped = false;
  bool matched = false;
  _Card(this.emoji);
}
