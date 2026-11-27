// ── ① 현재 세션 판정기: 번호표 + 계정 ──
class SessionGuard {
  int _generation = 0;
  String? _accountId;

  int get generation => _generation;
  String? get accountId => _accountId;

  // ── ② 검증된 새 세션 시작 (Bridge만 호출) ──
  int startSession(String accountId) {
    _accountId = accountId;
    return ++_generation;
  }

  // ── ③ 세션 무효화: 계정 비우고 번호 올림 ──
  void invalidate() {
    _accountId = null;
    _generation++;
  }

  // ── ④ "그 요청 시점의 세션이 아직 현재인가?" ──
  bool isCurrent(int generation, String accountId) =>
      _generation == generation && _accountId == accountId;
}
