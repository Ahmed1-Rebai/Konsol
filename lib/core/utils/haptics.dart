import 'package:vibration/vibration.dart';

class Haptics {
  Haptics._();

  static Future<void> connect() async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 20, amplitude: 128);
    }
  }

  static Future<void> disconnect() async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 10, amplitude: 64);
    }
  }

  static Future<void> error() async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: [0, 60, 40, 60]);
    }
  }

  static Future<void> success() async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: [0, 30, 50, 30]);
    }
  }

  static Future<void> light() async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 10, amplitude: 64);
    }
  }
}
