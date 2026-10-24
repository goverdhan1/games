import 'dart:math';

import 'package:flutter/material.dart';

/// Simplified Klondike solitaire (draw-one, unlimited recycles).
/// Tap a card to select it, then tap a tableau column or foundation to move.
/// Tap a selected card again to send it to its foundation.
class SolitaireScreen extends StatefulWidget {
  const SolitaireScreen({super.key});

  @override
  State<SolitaireScreen> createState() => _SolitaireScreenState();
}

class _PCard {
  final int suit; // 0 spades, 1 hearts, 2 clubs, 3 diamonds
  final int rank; // 1..13
  bool faceUp = false;
  _PCard(this.suit, this.rank);

  bool get isRed => suit == 1 || suit == 3;
  String get suitSymbol => const ['♠', '♥', '♣', '♦'][suit];
  String get rankLabel {
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return '$rank';
    }
  }
}

class _SolitaireScreenState extends State<SolitaireScreen> {
  final Random _rng = Random();
  List<_PCard> _stock = [];
  List<_PCard> _waste = [];
  List<List<_PCard>> _found = [];
  List<List<_PCard>> _tab = [];
  bool _selWaste = false;
  int _selCol = -1;
  int _selIdx = -1;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final deck = <_PCard>[];
    for (var s = 0; s < 4; s++) {
      for (var r = 1; r <= 13; r++) {
        deck.add(_PCard(s, r));
      }
    }
    deck.shuffle(_rng);
    _tab = List.generate(7, (_) => <_PCard>[]);
    for (var col = 0; col < 7; col++) {
      for (var i = 0; i <= col; i++) {
        final card = deck.removeLast();
        card.faceUp = i == col;
        _tab[col].add(card);
      }
    }
    _stock = deck;
    _waste = [];
    _found = List.generate(4, (_) => <_PCard>[]);
    _moves = 0;
    _clearSel();
  }

  void _clearSel() {
    _selWaste = false;
    _selCol = -1;
    _selIdx = -1;
  }

  bool get _hasSel => _selWaste || _selCol >= 0;

  bool get _won => _found.every((f) => f.length == 13);

  _PCard? get _selCard {
    if (_selWaste) return _waste.isEmpty ? null : _waste.last;
    if (_selCol >= 0 && _selIdx < _tab[_selCol].length) {
      return _tab[_selCol][_selIdx];
    }
    return null;
  }

  bool _canPlaceOnTableau(_PCard card, int col) {
    final pile = _tab[col];
    if (pile.isEmpty) return card.rank == 13;
    final top = pile.last;
    return top.faceUp && top.rank == card.rank + 1 && top.isRed != card.isRed;
  }

  bool _canPlaceOnFoundation(_PCard card, int idx) {
    final pile = _found[idx];
    if (pile.isEmpty) return card.rank == 1 && card.suit == idx;
    return pile.last.suit == card.suit && pile.last.rank + 1 == card.rank;
  }

  /// Removes the selected cards from their source and returns them.
  List<_PCard> _takeSelection() {
    if (_selWaste) return [_waste.removeLast()];
    final pile = _tab[_selCol];
    final taken = pile.sublist(_selIdx);
    pile.removeRange(_selIdx, pile.length);
    if (pile.isNotEmpty && !pile.last.faceUp) pile.last.faceUp = true;
    return taken;
  }

  bool _moveSelToTableau(int col) {
    final card = _selCard;
    if (card == null) return false;
    if (!_selWaste && _selCol == col) return false;
    if (!_canPlaceOnTableau(card, col)) return false;
    final taken = _takeSelection();
    _tab[col].addAll(taken);
    _moves++;
    _clearSel();
    return true;
  }

  bool _moveSelToFoundation(int idx) {
    final card = _selCard;
    if (card == null) return false;
    // only single (top) card can go to foundation
    if (!_selWaste && _selIdx != _tab[_selCol].length - 1) return false;
    if (!_canPlaceOnFoundation(card, idx)) return false;
    final taken = _takeSelection();
    _found[idx].addAll(taken);
    _moves++;
    _clearSel();
    return true;
  }

  bool _autoFoundation() {
    final card = _selCard;
    if (card == null) return false;
    return _moveSelToFoundation(card.suit);
  }

  void _onStock() {
    setState(() {
      _clearSel();
      if (_stock.isNotEmpty) {
        final c = _stock.removeLast();
        c.faceUp = true;
        _waste.add(c);
      } else if (_waste.isNotEmpty) {
        _stock = _waste.reversed.toList();
        for (final c in _stock) {
          c.faceUp = false;
        }
        _waste = [];
      }
    });
  }

  void _onWaste() {
    if (_waste.isEmpty) return;
    setState(() {
      if (_selWaste) {
        if (!_autoFoundation()) _clearSel();
      } else {
        _clearSel();
        _selWaste = true;
      }
    });
    _checkWin();
  }

  void _onFoundation(int idx) {
    setState(() {
      if (_hasSel) {
        if (!_moveSelToFoundation(idx)) _clearSel();
      }
    });
    _checkWin();
  }

  void _onTableauCard(int col, int idx) {
    setState(() {
      final card = _tab[col][idx];
      if (!card.faceUp) {
        if (idx == _tab[col].length - 1) card.faceUp = true;
        _clearSel();
        return;
      }
      if (_hasSel) {
        final same = !_selWaste && _selCol == col && _selIdx == idx;
        if (same) {
          if (!_autoFoundation()) _clearSel();
          return;
        }
        if (_moveSelToTableau(col)) return;
      }
      _clearSel();
      _selCol = col;
      _selIdx = idx;
    });
    _checkWin();
  }

  void _onEmptyColumn(int col) {
    setState(() {
      if (_hasSel) {
        if (!_moveSelToTableau(col)) _clearSel();
      }
    });
  }

  void _checkWin() {
    if (_won) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('You won!'),
            content: Text('Solved in $_moves moves.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(_deal);
                },
                child: const Text('New game'),
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
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        title: const Text('Solitaire'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('Moves: $_moves'),
            ),
          ),
          IconButton(
            tooltip: 'New game',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_deal),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, cons) {
            const pad = 6.0;
            const gap = 4.0;
            final cw = (cons.maxWidth - pad * 2 - gap * 7) / 7;
            final ch = cw * 1.4;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _slot(cw, gap, _stockWidget(cw, ch)),
                      _slot(cw, gap, _wasteWidget(cw, ch)),
                      _slot(cw, gap, SizedBox(height: ch)),
                      for (var i = 0; i < 4; i++)
                        _slot(cw, gap, _foundationWidget(i, cw, ch)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var c = 0; c < 7; c++)
                        _slot(cw, gap, _tableauColumn(c, cw, ch)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap a card to select, then tap a destination. '
                    'Tap a selected card again to send it to the foundation.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _slot(double cw, double gap, Widget child) => Padding(
        padding: EdgeInsets.only(right: gap),
        child: SizedBox(width: cw, child: child),
      );

  Widget _emptySlot(double cw, double ch, {String label = ''}) => Container(
        width: cw,
        height: ch,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white38),
          color: Colors.black12,
        ),
        child: Text(label,
            style: TextStyle(color: Colors.white38, fontSize: cw * 0.5)),
      );

  Widget _cardFace(_PCard c, double cw, double ch, bool selected) {
    final color = c.isRed ? Colors.red.shade700 : Colors.black87;
    return Container(
      width: cw,
      height: ch,
      padding: EdgeInsets.all(cw * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? Colors.orangeAccent : Colors.black54,
          width: selected ? 3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.rankLabel,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: cw * 0.30,
                      height: 1.0)),
              Text(c.suitSymbol,
                  style: TextStyle(color: color, fontSize: cw * 0.28, height: 1.0)),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(c.suitSymbol,
                  style: TextStyle(color: color, fontSize: cw * 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBack(double cw, double ch) => Container(
        width: cw,
        height: ch,
        decoration: BoxDecoration(
          color: Colors.indigo.shade700,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Icon(Icons.auto_awesome, color: Colors.white38, size: cw * 0.4),
        ),
      );

  Widget _stockWidget(double cw, double ch) {
    return GestureDetector(
      onTap: _onStock,
      child: _stock.isNotEmpty
          ? _cardBack(cw, ch)
          : _emptySlot(cw, ch, label: '↻'),
    );
  }

  Widget _wasteWidget(double cw, double ch) {
    return GestureDetector(
      onTap: _onWaste,
      child: _waste.isEmpty
          ? _emptySlot(cw, ch)
          : _cardFace(_waste.last, cw, ch, _selWaste),
    );
  }

  Widget _foundationWidget(int i, double cw, double ch) {
    final pile = _found[i];
    return GestureDetector(
      onTap: () => _onFoundation(i),
      child: pile.isEmpty
          ? _emptySlot(cw, ch, label: const ['♠', '♥', '♣', '♦'][i])
          : _cardFace(pile.last, cw, ch, false),
    );
  }

  Widget _tableauColumn(int col, double cw, double ch) {
    final pile = _tab[col];
    if (pile.isEmpty) {
      return GestureDetector(
        onTap: () => _onEmptyColumn(col),
        child: _emptySlot(cw, ch, label: 'K'),
      );
    }
    final downStep = ch * 0.16;
    final upStep = ch * 0.30;
    final offsets = <double>[];
    var y = 0.0;
    for (var i = 0; i < pile.length; i++) {
      offsets.add(y);
      y += pile[i].faceUp ? upStep : downStep;
    }
    final height = offsets.last + ch;
    return SizedBox(
      width: cw,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < pile.length; i++)
            Positioned(
              top: offsets[i],
              left: 0,
              child: GestureDetector(
                onTap: () => _onTableauCard(col, i),
                child: pile[i].faceUp
                    ? _cardFace(
                        pile[i],
                        cw,
                        ch,
                        !_selWaste && _selCol == col && i >= _selIdx,
                      )
                    : _cardBack(cw, ch),
              ),
            ),
        ],
      ),
    );
  }
}
