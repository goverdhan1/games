import 'package:flutter/services.dart';

import '../settings.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  void click() {
    if (!AppSettings.instance.soundEnabled) return;
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  void dice() => click();

  void move() {
    if (!AppSettings.instance.soundEnabled) return;
    HapticFeedback.selectionClick();
  }

  void capture() {
    if (!AppSettings.instance.soundEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void win() {
    if (!AppSettings.instance.soundEnabled) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }
}
