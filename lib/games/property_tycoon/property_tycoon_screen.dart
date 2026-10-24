import 'dart:math';

import 'package:flutter/material.dart';

/// Property Tycoon (lite): roll, move around a 24-tile ring, buy properties and
/// collect rent from the CPU. Bankrupt your rival, or be richest after 30 rounds.
class PropertyTycoonScreen extends StatefulWidget {
  const PropertyTycoonScreen({super.key});

  @override
  State<PropertyTycoonScreen> createState() => _PropertyTycoonScreenState();
}

enum _T { start, property, tax, chance, jail, parking, goJail }

class _Tile {
  final String name;
  final _T type;
  final int price;
  final int rent;
  final int group; // -1 for non-property
  const _Tile(this.name, this.type,
      {this.price = 0, this.rent = 0, this.group = -1});
}

const List<Color> _groupColors = [
  Color(0xFF8D6E63), // 0 brown
  Color(0xFF4FC3F7), // 1 sky
  Color(0xFFF06292), // 2 pink
  Color(0xFFFFA726), // 3 orange
  Color(0xFFE53935), // 4 red
  Color(0xFFFDD835), // 5 yellow
  Color(0xFF43A047), // 6 green
  Color(0xFF1E3A8A), // 7 blue
];

const List<_Tile> _tiles = [
  _Tile('START', _T.start), // 0
  _Tile('Brown Alley', _T.property, price: 60, rent: 6, group: 0),
  _Tile('Brown Lane', _T.property, price: 60, rent: 8, group: 0),
  _Tile('Chance', _T.chance),
  _Tile('Sky St', _T.property, price: 100, rent: 10, group: 1),
  _Tile('Sky Ave', _T.property, price: 120, rent: 12, group: 1),
  _Tile('JAIL (visit)', _T.jail), // 6
  _Tile('Pink Plaza', _T.property, price: 140, rent: 14, group: 2),
  _Tile('Pink Row', _T.property, price: 160, rent: 16, group: 2),
  _Tile('Tax \$100', _T.tax, price: 100),
  _Tile('Orange Mile', _T.property, price: 180, rent: 18, group: 3),
  _Tile('Orange Way', _T.property, price: 200, rent: 20, group: 3),
  _Tile('FREE PARKING', _T.parking), // 12
  _Tile('Red Road', _T.property, price: 220, rent: 22, group: 4),
  _Tile('Red Court', _T.property, price: 240, rent: 24, group: 4),
  _Tile('Chance', _T.chance),
  _Tile('Yellow Gate', _T.property, price: 260, rent: 26, group: 5),
  _Tile('Yellow Park', _T.property, price: 280, rent: 28, group: 5),
  _Tile('GO TO JAIL', _T.goJail), // 18
  _Tile('Green Hill', _T.property, price: 300, rent: 30, group: 6),
  _Tile('Tax \$150', _T.tax, price: 150),
  _Tile('Green Vale', _T.property, price: 320, rent: 32, group: 6),
  _Tile('Blue Tower', _T.property, price: 350, rent: 35, group: 7),
  _Tile('Blue Crown', _T.property, price: 400, rent: 50, group: 7),
];

class _Player {
  final String name;
  final Color color;
  int cash = 1500;
  int pos = 0;
  bool jailed = false;
  _Player(this.name, this.color);
}

enum _Phase { roll, buy, cpu, over }

class _PropertyTycoonScreenState extends State<PropertyTycoonScreen> {
  static const int _maxRounds = 30;
  final Random _rng = Random();

  late List<_Player> _players;
  late List<int?> _owner;
  _Phase _phase = _Phase.roll;
  int _round = 1;
  int _d1 = 1;
  int _d2 = 1;
  final List<String> _log = [];
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _gen++;
    _players = [
      _Player('You', const Color(0xFF1976D2)),
      _Player('CPU', const Color(0xFFD81B60)),
    ];
    _owner = List<int?>.filled(_tiles.length, null);
    _phase = _Phase.roll;
    _round = 1;
    _d1 = 1;
    _d2 = 1;
    _log
      ..clear()
      ..add('Welcome! Everyone starts with \$1500. Roll the dice.');
    setState(() {});
  }

  void _say(String s) {
    _log.add(s);
    if (_log.length > 40) _log.removeAt(0);
  }

  int _netWorth(int p) {
    var w = _players[p].cash;
    for (var i = 0; i < _tiles.length; i++) {
      if (_owner[i] == p) w += _tiles[i].price;
    }
    return w;
  }

  bool _ownsGroup(int p, int group) {
    for (var i = 0; i < _tiles.length; i++) {
      if (_tiles[i].group == group && _owner[i] != p) return false;
    }
    return true;
  }

  int _rentFor(int index) {
    final t = _tiles[index];
    final o = _owner[index]!;
    return _ownsGroup(o, t.group) ? t.rent * 2 : t.rent;
  }

  void _onRollTap() {
    if (_phase != _Phase.roll) return;
    _takeTurn(0);
  }

  /// Performs a full turn for [p]. Returns true if a decision (buy) is pending.
  void _takeTurn(int p) {
    final pl = _players[p];
    final who = pl.name;
    if (pl.jailed) {
      pl.jailed = false;
      setState(() {
        _say('$who missed a turn in jail.');
      });
      _endTurn(p);
      return;
    }
    _d1 = _rng.nextInt(6) + 1;
    _d2 = _rng.nextInt(6) + 1;
    final steps = _d1 + _d2;
    final old = pl.pos;
    pl.pos = (pl.pos + steps) % _tiles.length;
    if (pl.pos < old) {
      pl.cash += 200;
      _say('$who passed START (+\$200).');
    }
    _say('$who rolled $_d1 + $_d2 = $steps → ${_tiles[pl.pos].name}.');
    final needsBuy = _resolve(p);
    setState(() {});
    if (_phase == _Phase.over) return;
    if (needsBuy) {
      if (p == 0) {
        setState(() => _phase = _Phase.buy);
      } else {
        final t = _tiles[pl.pos];
        if (pl.cash - t.price >= 200) {
          _buy(p);
        } else {
          setState(() => _say('CPU passed on ${t.name}.'));
        }
        _endTurn(p);
      }
      return;
    }
    _endTurn(p);
  }

  /// Applies the landing effect. Returns true if the tile can be bought.
  bool _resolve(int p) {
    final pl = _players[p];
    final idx = pl.pos;
    final t = _tiles[idx];
    switch (t.type) {
      case _T.property:
        final o = _owner[idx];
        if (o == null) return pl.cash >= t.price;
        if (o != p) {
          final rent = _rentFor(idx);
          _pay(p, rent, to: o);
          _say('${pl.name} paid \$$rent rent to ${_players[o].name}.');
        }
        return false;
      case _T.tax:
        _pay(p, t.price);
        _say('${pl.name} paid \$${t.price} tax.');
        return false;
      case _T.chance:
        _chance(p);
        return false;
      case _T.goJail:
        pl.pos = 6;
        pl.jailed = true;
        _say('${pl.name} goes to jail (miss next turn).');
        return false;
      case _T.parking:
        _say('${pl.name} rests at Free Parking.');
        return false;
      case _T.start:
      case _T.jail:
        return false;
    }
  }

  void _chance(int p) {
    final pl = _players[p];
    switch (_rng.nextInt(6)) {
      case 0:
        pl.cash += 100;
        _say('Chance: bank dividend, ${pl.name} +\$100.');
        break;
      case 1:
        _pay(p, 50);
        _say('Chance: repair bill, ${pl.name} -\$50.');
        break;
      case 2:
        pl.pos = 0;
        pl.cash += 200;
        _say('Chance: ${pl.name} jumps to START (+\$200).');
        break;
      case 3:
        pl.cash += 75;
        _say('Chance: lucky find, ${pl.name} +\$75.');
        break;
      case 4:
        _pay(p, 80);
        _say('Chance: speeding fine, ${pl.name} -\$80.');
        break;
      default:
        pl.pos = 6;
        pl.jailed = true;
        _say('Chance: ${pl.name} goes to jail (miss next turn).');
    }
  }

  void _pay(int p, int amount, {int? to}) {
    _players[p].cash -= amount;
    if (to != null) _players[to].cash += amount;
    if (_players[p].cash < 0) {
      _phase = _Phase.over;
      _say('${_players[p].name} is bankrupt! '
          '${_players[to ?? (1 - p)].name} wins.');
    }
  }

  void _buy(int p) {
    final pl = _players[p];
    final t = _tiles[pl.pos];
    setState(() {
      pl.cash -= t.price;
      _owner[pl.pos] = p;
      _say('${pl.name} bought ${t.name} for \$${t.price}.');
    });
  }

  void _onBuyTap() {
    if (_phase != _Phase.buy) return;
    _buy(0);
    _endTurn(0);
  }

  void _onSkipTap() {
    if (_phase != _Phase.buy) return;
    setState(() => _say('You passed on ${_tiles[_players[0].pos].name}.'));
    _endTurn(0);
  }

  void _endTurn(int p) {
    if (_phase == _Phase.over) {
      setState(() {});
      return;
    }
    if (p == 0) {
      setState(() => _phase = _Phase.cpu);
      final gen = _gen;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || gen != _gen || _phase != _Phase.cpu) return;
        _takeTurn(1);
      });
    } else {
      setState(() {
        _round++;
        if (_round > _maxRounds) {
          _phase = _Phase.over;
          final a = _netWorth(0);
          final b = _netWorth(1);
          _say(a == b
              ? 'Time! It is a tie at \$$a.'
              : (a > b
                  ? 'Time! You win with net worth \$$a vs \$$b.'
                  : 'Time! CPU wins with net worth \$$b vs \$$a.'));
        } else {
          _phase = _Phase.roll;
        }
      });
    }
  }

  (int, int) _cellOf(int i) {
    if (i <= 5) return (6, 6 - i); // bottom row, right → left
    if (i <= 11) return (6 - (i - 6), 0); // left column, bottom → top
    if (i <= 17) return (0, i - 12); // top row, left → right
    return (i - 18, 6); // right column, top → bottom
  }

  @override
  Widget build(BuildContext context) {
    final over = _phase == _Phase.over;
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Property Tycoon'),
        backgroundColor: const Color(0xFFAD1457),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'New game',
            icon: const Icon(Icons.refresh),
            onPressed: _newGame,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, cons) {
          final side = min(cons.maxWidth, 520.0);
          return SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: side,
                child: Column(
                  children: [
                    _board(side),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(child: _playerCard(0)),
                          const SizedBox(width: 10),
                          Expanded(child: _playerCard(1)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_phase == _Phase.roll)
                          ElevatedButton.icon(
                            onPressed: _onRollTap,
                            icon: const Icon(Icons.casino),
                            label: const Text('Roll dice'),
                          ),
                        if (_phase == _Phase.buy) ...[
                          ElevatedButton.icon(
                            onPressed: _onBuyTap,
                            icon: const Icon(Icons.shopping_cart),
                            label: Text(
                                'Buy \$${_tiles[_players[0].pos].price}'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: _onSkipTap,
                            child: const Text('Skip'),
                          ),
                        ],
                        if (_phase == _Phase.cpu)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('CPU is playing...'),
                          ),
                        if (over)
                          ElevatedButton.icon(
                            onPressed: _newGame,
                            icon: const Icon(Icons.replay),
                            label: const Text('Play again'),
                          ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in _log.reversed.take(6))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(line,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _playerCard(int p) {
    final pl = _players[p];
    final owned = <int>[];
    for (var i = 0; i < _tiles.length; i++) {
      if (_owner[i] == p) owned.add(i);
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pl.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(radius: 7, backgroundColor: pl.color),
            const SizedBox(width: 6),
            Text(pl.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text('Cash: \$${pl.cash}'),
          Text('Net worth: \$${_netWorth(p)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: [
              for (final i in owned)
                Container(
                  width: 12,
                  height: 12,
                  color: _groupColors[_tiles[i].group],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _board(double side) {
    final cell = side / 7;
    final children = <Widget>[];

    for (var i = 0; i < _tiles.length; i++) {
      final (row, col) = _cellOf(i);
      children.add(Positioned(
        left: col * cell,
        top: row * cell,
        width: cell,
        height: cell,
        child: _tileView(i),
      ));
    }

    // Centre panel.
    children.add(Positioned(
      left: cell,
      top: cell,
      width: cell * 5,
      height: cell * 5,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFFC8E6C9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PROPERTY TYCOON',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFFAD1457))),
            const SizedBox(height: 6),
            Text('Round ${min(_round, _maxRounds)} / $_maxRounds',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_die(_d1), const SizedBox(width: 10), _die(_d2)],
            ),
          ],
        ),
      ),
    ));

    // Tokens.
    for (var p = 0; p < 2; p++) {
      final pl = _players[p];
      final (row, col) = _cellOf(pl.pos);
      children.add(Positioned(
        left: col * cell + cell * (p == 0 ? 0.12 : 0.55),
        top: row * cell + cell * 0.55,
        width: cell * 0.33,
        height: cell * 0.33,
        child: Container(
          decoration: BoxDecoration(
            color: pl.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ));
    }

    return SizedBox(
      width: side,
      height: side,
      child: Stack(children: children),
    );
  }

  Widget _die(int v) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: Text('$v',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }

  Widget _tileView(int i) {
    final t = _tiles[i];
    final o = _owner[i];
    Color bg = Colors.white;
    String sub = '';
    switch (t.type) {
      case _T.start:
        bg = const Color(0xFFFFF59D);
        sub = '+\$200';
        break;
      case _T.property:
        sub = '\$${t.price}';
        break;
      case _T.tax:
        bg = const Color(0xFFFFCDD2);
        break;
      case _T.chance:
        bg = const Color(0xFFD1C4E9);
        sub = '?';
        break;
      case _T.jail:
        bg = const Color(0xFFB0BEC5);
        break;
      case _T.parking:
        bg = const Color(0xFFB2DFDB);
        break;
      case _T.goJail:
        bg = const Color(0xFFEF9A9A);
        break;
    }
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: o == null ? Colors.black45 : _players[o].color,
          width: o == null ? 1 : 3,
        ),
      ),
      child: Column(
        children: [
          if (t.type == _T.property)
            Container(height: 7, color: _groupColors[t.group]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    sub.isEmpty ? t.name : '${t.name}\n$sub',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8, height: 1.1),
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
