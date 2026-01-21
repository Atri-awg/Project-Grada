import 'dart:async';
import 'package:flutter/material.dart';

class TimerProvider with ChangeNotifier {
  Timer? _timer;

  // 1. Tambahkan total waktu awal sebagai acuan (25 menit)
  final int _initialSeconds = 25 * 60;
  int _seconds = 25 * 60;
  bool _isRunning = false;

  int get seconds => _seconds;
  bool get isRunning => _isRunning;

  // 2. INI KUNCINYA: Buat getter percent untuk menghitung sisa lingkaran
  double get percent {
    // Rumus: sisa detik dibagi total detik awal
    double val = _seconds / _initialSeconds;

    // Safety check supaya nilainya tetap di antara 0.0 - 1.0
    if (val > 1.0) return 1.0;
    if (val < 0.0) return 0.0;
    return val;
  }

  String get timeString {
    int minutes = _seconds ~/ 60;
    int remainingSeconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        _seconds--;
        notifyListeners(); // Penting: memberitahu UI untuk update lingkaran & teks
      } else {
        stopTimer();
      }
    });
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _seconds = _initialSeconds;
    notifyListeners();
  }
}
