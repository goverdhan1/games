import 'package:flutter/material.dart';

import '../settings.dart';
import 'feedback_screen.dart';
import 'game_catalog.dart';

class HubHome extends StatefulWidget {
  const HubHome({super.key});

  @override
  State<HubHome> createState() => _HubHomeState();
}

class _HubHomeState extends State<HubHome> {
  GameWave? _filter;

  @override
  Widget build(BuildContext context) {
    final games = _filter == null
        ? kGameCatalog
        : kGameCatalog.where((g) => g.wave == _filter).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF004D40), Color(0xFF1B5E20)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Classic Games',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Hub · offline · free',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sound',
                      onPressed: () async {
                        setState(() {
                          AppSettings.instance.soundEnabled =
                              !AppSettings.instance.soundEnabled;
                        });
                        await AppSettings.instance.save();
                      },
                      icon: Icon(
                        AppSettings.instance.soundEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Feedback',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FeedbackScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.feedback_outlined, color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _chip('All', null),
                    _chip('Wave 1', GameWave.wave1),
                    _chip('Wave 2', GameWave.wave2),
                    _chip('Wave 3', GameWave.wave3),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: games.length,
                  itemBuilder: (context, i) {
                    final g = games[i];
                    return _GameTile(
                      entry: g,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: g.builder),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, GameWave? wave) {
    final selected = _filter == wave;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = wave),
        selectedColor: Colors.amber.shade400,
        labelStyle: TextStyle(
          color: selected ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.white24,
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final GameEntry entry;
  final VoidCallback onTap;

  const _GameTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(entry.icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
