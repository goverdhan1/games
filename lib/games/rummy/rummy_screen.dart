import 'dart:math';

import 'package:flutter/material.dart';

class RummyScreen extends StatefulWidget {
  const RummyScreen({super.key});

  @override
  State<RummyScreen> createState() => _RummyScreenState();
}

class _RCard {
  final int rank;
  final int suit;
  _RCard(this.rank, this.suit);
  String get label {
    const r = ['', 'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
    const s = ['♠', '♥', '♦', '♣'];
    return '${r[rank]}${s[suit]}';
  }

  bool get red => suit == 1 || suit == 2;
}

class _RummyScreenState extends State<RummyScreen> {
  late List<_RCard> deck;
  late List<_RCard> you;
  late List<_RCard> discard;
  final _rng = Random();
  String status = 'Draw, then discard. Declare if you have a set or run.';

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    deck = [for (var s = 0; s < 4; s++) for (var r = 1; r <= 13; r++) _RCard(r, s)]..shuffle(_rng);
    you = deck.sublist(0, 7);
    deck = deck.sublist(7);
    discard = [deck.removeLast()];
    status = 'Draw from deck or discard pile';
    setState(() {});
  }

  bool _hasMeld(List<_RCard> hand) {
    final byRank = <int, int>{};
    for (final c in hand) {
      byRank[c.rank] = (byRank[c.rank] ?? 0) + 1;
    }
    if (byRank.values.any((n) => n >= 3)) return true;
    final bySuit = <int, List<int>>{};
    for (final c in hand) {
      bySuit.putIfAbsent(c.suit, () => []).add(c.rank);
    }
    for (final ranks in bySuit.values) {
      ranks.sort();
      var run = 1;
      for (var i = 1; i < ranks.length; i++) {
        if (ranks[i] == ranks[i - 1] + 1) {
          run++;
          if (run >= 3) return true;
        } else if (ranks[i] != ranks[i - 1]) {
          run = 1;
        }
      }
    }
    return false;
  }

  void _drawDeck() {
    if (deck.isEmpty) return;
    you.add(deck.removeLast());
    setState(() => status = 'Now discard a card');
  }

  void _drawDiscard() {
    if (discard.isEmpty) return;
    you.add(discard.removeLast());
    setState(() => status = 'Now discard a card');
  }

  void _discard(int i) {
    discard.add(you.removeAt(i));
    setState(() => status = 'Your turn — draw again or Declare');
  }

  void _declare() {
    if (_hasMeld(you)) {
      setState(() => status = 'You declared — You win!');
    } else {
      setState(() => status = 'No valid set/run yet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rummy Lite'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _deal, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Text(status, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(onPressed: _drawDeck, child: Text('Deck (${deck.length})')),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _drawDiscard,
                child: Container(
                  width: 56,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(), borderRadius: BorderRadius.circular(8)),
                  child: Text(discard.isEmpty ? '' : discard.last.label, style: TextStyle(color: discard.isEmpty ? null : (discard.last.red ? Colors.red : Colors.black), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: you.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = you[i];
                return GestureDetector(
                  onTap: () => _discard(i),
                  child: Container(
                    width: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all()),
                    child: Text(c.label, style: TextStyle(color: c.red ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(onPressed: _declare, child: const Text('Declare')),
          ),
        ],
      ),
    );
  }
}
