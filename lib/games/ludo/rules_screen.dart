import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const rules = [
      ('Start', 'Roll a 6 to move a token out of your yard onto the board.'),
      ('Move', 'Move one token forward by the number on the dice.'),
      ('Extra turn', 'Rolling a 6 or capturing an opponent grants another roll.'),
      ('Three 6s', 'Three sixes in a row skip your turn.'),
      ('Capture', 'Land on an opponent (not on a star/safe square) to send them home.'),
      ('Safe squares', 'Star squares and starting squares are safe.'),
      ('Home', 'Enter your colored home stretch and finish with an exact roll.'),
      ('Win', 'Get all four tokens to the center to win.'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('How to play'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: rules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final (title, body) = rules[i];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32),
              child: Text(
                '${i + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(body),
          );
        },
      ),
    );
  }
}
