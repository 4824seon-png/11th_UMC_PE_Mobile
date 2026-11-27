// 로그인 상태의 주인 이 바뀔 때마다, 그 변화를 SessionGuard(번호표 판정기)에 반영

import 'package:flutter/foundation.dart';

import 'session_guard.dart';

// ── ① AuthViewModel의 변화를 SessionGuard에 전달하는 연결선 ──
class AuthSessionBridge {
  AuthSessionBridge({
    required this.authSignals,
    required this.sessionVersion,
    required this.verifiedEmail,
  }) {
    // ── ② 생성 즉시 구독하고, 현재 상태를 한 번 반영 ──
    authSignals.addListener(_sync);
    _sync();
  }

  // ── ③ 구체 클래스 대신 '신호'와 '값 읽는 함수'만 받음 ──
  final Listenable authSignals;
  final int Function() sessionVersion;
  final String? Function() verifiedEmail;

  final guard = SessionGuard();
  int? _seenVersion;
  String? _seenEmail;
  bool _disposed = false;

  // ── ④ 버전이나 이메일이 바뀌었을 때만 세션을 다시 시작 ──
  void _sync() {
    if (_disposed) return;
    final version = sessionVersion();
    final email = verifiedEmail();
    if (version == _seenVersion && email == _seenEmail) return;
    _seenVersion = version;
    _seenEmail = email;
    guard.invalidate();
    if (email != null) guard.startSession(email);
  }

  // ── ⑤ 구독 해제 + 세션 무효화 ──
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    authSignals.removeListener(_sync);
    guard.invalidate();
  }
}
