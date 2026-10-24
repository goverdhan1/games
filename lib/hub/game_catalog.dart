import 'package:flutter/material.dart';

import '../games/carrom/carrom_screen.dart';
import '../games/checkers/checkers_screen.dart';
import '../games/chess/chess_screen.dart';
import '../games/color_cards/color_cards_screen.dart';
import '../games/connect_four/connect_four_screen.dart';
import '../games/dominoes/dominoes_screen.dart';
import '../games/flyer/flyer_screen.dart';
import '../games/game2048/game2048_screen.dart';
import '../games/ludo/home_screen.dart' as ludo;
import '../games/memory/memory_screen.dart';
import '../games/property_tycoon/property_tycoon_screen.dart';
import '../games/rummy/rummy_screen.dart';
import '../games/snake/snake_screen.dart';
import '../games/snake_ladder/snake_ladder_screen.dart';
import '../games/solitaire/solitaire_screen.dart';
import '../games/sudoku/sudoku_screen.dart';
import '../games/tictactoe/tictactoe_screen.dart';
import '../games/trivia/trivia_screen.dart';
import '../games/word_rack/word_rack_screen.dart';
import '../games/wordle/wordle_screen.dart';

enum GameWave { wave1, wave2, wave3 }

class GameEntry {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final GameWave wave;
  final WidgetBuilder builder;

  const GameEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.wave,
    required this.builder,
  });
}

final List<GameEntry> kGameCatalog = [
  GameEntry(
    id: 'ludo',
    title: 'Ludo',
    subtitle: 'Classic · local & AI',
    icon: Icons.casino,
    color: const Color(0xFFE53935),
    wave: GameWave.wave1,
    builder: (_) => const ludo.HomeScreen(),
  ),
  GameEntry(
    id: 'snake_ladder',
    title: 'Snake & Ladder',
    subtitle: 'Race to 100',
    icon: Icons.stairs,
    color: const Color(0xFF43A047),
    wave: GameWave.wave1,
    builder: (_) => const SnakeLadderScreen(),
  ),
  GameEntry(
    id: 'tictactoe',
    title: 'Tic-Tac-Toe',
    subtitle: 'Vs friend or AI',
    icon: Icons.grid_3x3,
    color: const Color(0xFF1E88E5),
    wave: GameWave.wave1,
    builder: (_) => const TicTacToeScreen(),
  ),
  GameEntry(
    id: 'connect_four',
    title: 'Connect Four',
    subtitle: 'Drop & connect',
    icon: Icons.view_week,
    color: const Color(0xFFFDD835),
    wave: GameWave.wave1,
    builder: (_) => const ConnectFourScreen(),
  ),
  GameEntry(
    id: 'memory',
    title: 'Memory Match',
    subtitle: 'Find the pairs',
    icon: Icons.style,
    color: const Color(0xFF8E24AA),
    wave: GameWave.wave1,
    builder: (_) => const MemoryScreen(),
  ),
  GameEntry(
    id: '2048',
    title: '2048',
    subtitle: 'Merge the tiles',
    icon: Icons.grid_on,
    color: const Color(0xFFFB8C00),
    wave: GameWave.wave1,
    builder: (_) => const Game2048Screen(),
  ),
  GameEntry(
    id: 'snake',
    title: 'Snake',
    subtitle: 'Arcade classic',
    icon: Icons.polyline,
    color: const Color(0xFF00897B),
    wave: GameWave.wave1,
    builder: (_) => const SnakeScreen(),
  ),
  GameEntry(
    id: 'chess',
    title: 'Chess',
    subtitle: 'Play vs AI',
    icon: Icons.castle,
    color: const Color(0xFF5D4037),
    wave: GameWave.wave2,
    builder: (_) => const ChessScreen(),
  ),
  GameEntry(
    id: 'checkers',
    title: 'Checkers',
    subtitle: 'Draughts vs AI',
    icon: Icons.circle,
    color: const Color(0xFF37474F),
    wave: GameWave.wave2,
    builder: (_) => const CheckersScreen(),
  ),
  GameEntry(
    id: 'solitaire',
    title: 'Solitaire',
    subtitle: 'Klondike cards',
    icon: Icons.style_outlined,
    color: const Color(0xFF2E7D32),
    wave: GameWave.wave2,
    builder: (_) => const SolitaireScreen(),
  ),
  GameEntry(
    id: 'sudoku',
    title: 'Sudoku',
    subtitle: 'Number puzzle',
    icon: Icons.apps,
    color: const Color(0xFF1565C0),
    wave: GameWave.wave2,
    builder: (_) => const SudokuScreen(),
  ),
  GameEntry(
    id: 'wordle',
    title: 'Word Quest',
    subtitle: 'Guess the word',
    icon: Icons.abc,
    color: const Color(0xFF6A1B9A),
    wave: GameWave.wave2,
    builder: (_) => const WordleScreen(),
  ),
  GameEntry(
    id: 'flyer',
    title: 'Sky Dash',
    subtitle: 'Endless flyer',
    icon: Icons.flight,
    color: const Color(0xFF0277BD),
    wave: GameWave.wave2,
    builder: (_) => const FlyerScreen(),
  ),
  GameEntry(
    id: 'trivia',
    title: 'Trivia Quiz',
    subtitle: 'Test your knowledge',
    icon: Icons.quiz,
    color: const Color(0xFFC62828),
    wave: GameWave.wave2,
    builder: (_) => const TriviaScreen(),
  ),
  GameEntry(
    id: 'dominoes',
    title: 'Dominoes',
    subtitle: 'Match the pips',
    icon: Icons.view_module,
    color: const Color(0xFF455A64),
    wave: GameWave.wave3,
    builder: (_) => const DominoesScreen(),
  ),
  GameEntry(
    id: 'color_cards',
    title: 'Color Cards',
    subtitle: 'Match colors & ranks',
    icon: Icons.filter_none,
    color: const Color(0xFFD32F2F),
    wave: GameWave.wave3,
    builder: (_) => const ColorCardsScreen(),
  ),
  GameEntry(
    id: 'rummy',
    title: 'Rummy Lite',
    subtitle: 'Sets & runs',
    icon: Icons.layers,
    color: const Color(0xFF00695C),
    wave: GameWave.wave3,
    builder: (_) => const RummyScreen(),
  ),
  GameEntry(
    id: 'carrom',
    title: 'Carrom Lite',
    subtitle: 'Pocket the coins',
    icon: Icons.sports_hockey,
    color: const Color(0xFF4E342E),
    wave: GameWave.wave3,
    builder: (_) => const CarromScreen(),
  ),
  GameEntry(
    id: 'property_tycoon',
    title: 'Property Tycoon',
    subtitle: 'Buy & race lite',
    icon: Icons.apartment,
    color: const Color(0xFFAD1457),
    wave: GameWave.wave3,
    builder: (_) => const PropertyTycoonScreen(),
  ),
  GameEntry(
    id: 'word_rack',
    title: 'Word Rack',
    subtitle: 'Build words',
    icon: Icons.spellcheck,
    color: const Color(0xFFEF6C00),
    wave: GameWave.wave3,
    builder: (_) => const WordRackScreen(),
  ),
];
