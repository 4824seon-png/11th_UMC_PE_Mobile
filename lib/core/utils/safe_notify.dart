import 'package:flutter/foundation.dart';

// ── ① ChangeNotifier에만 붙일 수 있는 mixin ──
mixin SafeNotify on ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  // ── ② dispose 시점을 기록 ──
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── ③ 살아 있을 때만 알림 ──
  void notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }
}
