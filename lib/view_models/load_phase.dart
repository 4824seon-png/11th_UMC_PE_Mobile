// ── ① 목록 화면의 첫 조회 상태 ──
enum LoadPhase {
  idle, // 아직 요청 전
  loading, // 첫 page 로딩 중 (조건이 바뀐 새 첫 page 포함)
  ready, // 표시할 목록 있음
  empty, // 성공했지만 결과 0건
  error, // 첫 조회 실패
}
