import 'package:flutter/services.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool soundEnabled = true;

  void playClick() {
    if (!soundEnabled) return;
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void playSuccess() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playLevelUp() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playAwakening() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playDungeonAlert() {
    if (!soundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }
}
