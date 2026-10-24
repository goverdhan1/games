import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _soundKey = 'sound_enabled';
  static const _playersKey = 'player_count';
  static const _humansKey = 'human_count';

  bool soundEnabled = true;
  int playerCount = 4;
  int humanCount = 1;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled = prefs.getBool(_soundKey) ?? true;
    playerCount = prefs.getInt(_playersKey) ?? 4;
    humanCount = prefs.getInt(_humansKey) ?? 1;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, soundEnabled);
    await prefs.setInt(_playersKey, playerCount);
    await prefs.setInt(_humansKey, humanCount);
  }
}
