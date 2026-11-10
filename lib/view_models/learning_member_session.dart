import 'package:flutter/foundation.dart';

class LearningMemberSession extends ChangeNotifier {
  // ── ① 상태: 현재 학습용 회원 번호 (가입 전에는 null) ──
  int? memberId; // 가입 전에는 번호가 없으므로 null 아직 가입 안 함을 별도 bool 없이 null 하나로 표현

  // ── ② 가입 성공 시 번호 저장 + 구독자에게 알림 ──
  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  // ── ③ 번호 지우기 + 구독자에게 알림 ──
  void clear() {
    memberId = null;
    notifyListeners();
  }
}
