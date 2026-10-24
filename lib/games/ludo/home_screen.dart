import 'package:flutter/material.dart';

import 'models.dart';
import '../../settings.dart';
import 'game_screen.dart';
import 'rules_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _playerCount;
  late int _humanCount;
  late bool _sound;

  @override
  void initState() {
    super.initState();
    final s = AppSettings.instance;
    _playerCount = s.playerCount;
    _humanCount = s.humanCount.clamp(1, _playerCount);
    _sound = s.soundEnabled;
  }

  Future<void> _persist() async {
    final s = AppSettings.instance;
    s.playerCount = _playerCount;
    s.humanCount = _humanCount;
    s.soundEnabled = _sound;
    await s.save();
  }

  List<PlayerConfig> _buildConfigs() {
    const colors = PlayerColor.values;
    final configs = <PlayerConfig>[];
    for (var i = 0; i < _playerCount; i++) {
      final isHuman = i < _humanCount;
      configs.add(
        PlayerConfig(
          color: colors[i],
          type: isHuman ? PlayerType.human : PlayerType.ai,
          name: isHuman
              ? (_humanCount == 1 ? 'You' : 'Player ${i + 1}')
              : 'CPU ${colors[i].label}',
        ),
      );
    }
    return configs;
  }

  void _start() {
    _persist();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(configs: _buildConfigs()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF004D40), Color(0xFF0D47A1)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'LUDO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Classic board game · local & AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Players',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 2, label: Text('2')),
                          ButtonSegment(value: 3, label: Text('3')),
                          ButtonSegment(value: 4, label: Text('4')),
                        ],
                        selected: {_playerCount},
                        onSelectionChanged: (v) {
                          setState(() {
                            _playerCount = v.first;
                            if (_humanCount > _playerCount) {
                              _humanCount = _playerCount;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Human players',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rest are AI · pass-and-play for multiple humans',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Slider(
                        value: _humanCount.toDouble(),
                        min: 1,
                        max: _playerCount.toDouble(),
                        divisions: _playerCount - 1,
                        label: '$_humanCount',
                        activeColor: const Color(0xFF2E7D32),
                        onChanged: (v) =>
                            setState(() => _humanCount = v.round()),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sound & haptics'),
                        value: _sound,
                        activeThumbColor: const Color(0xFF2E7D32),
                        onChanged: (v) => setState(() => _sound = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: const Color(0xFF3E2723),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('New Game'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RulesScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('How to play'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
