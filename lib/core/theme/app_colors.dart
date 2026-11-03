import 'package:flutter/material.dart';

/// Figma 디자인 시스템의 원본 색상값 모음.
/// 화면에서는 이 값을 직접 쓰지 않고 Theme의 ColorScheme을 통해 사용한다.
class AppColors {
  AppColors._(); // 인스턴스를 만들 필요가 없으므로 생성자를 막는다.

  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAF9F5);
  // 기본 텍스트 (W3-02 카드 제목)
  static const Color onSurface = Color(0xFF1D1B20);
  // 보조 텍스트·아이콘 (W3-02 부제·검색 아이콘·미선택 Chip 글자)
  static const Color onSurfaceVariant = Color(0xFF494551);
  static const Color surfaceContainer = Color(0xFFF3F1EC); // 통계 카드 배경
  // 미선택 Chip·포스터 자리 배경 (W3-02)
  static const Color surfaceContainerHighest = Color(0xFFE6E0E9);
  // 평점 뱃지 배경 (W3-02, 80% 불투명으로 사용) / 뱃지 글자
  static const Color inverseSurface = Color(0xFF322F35);
  static const Color onInverseSurface = Color(0xFFF5EFF7);
  static const Color outlineVariant = Color(0xFFE3E0D8); // 통계 카드 테두리
  static const Color secondaryContainer = Color(0xFFE9DDFF); // 장르 Chip 배경
  static const Color inputBorder = Color(0xFFD9D3E1); // 입력창 기본 테두리
  static const Color inputFill = Color(0xFFFEFCF9); // 입력창 배경
  static const Color inputHint = Color(0xFF8A8391); // 힌트 글자
  static const Color labelText = Color(0xFF25232A); // 라벨·본문 글자
  static const Color buttonDisabled = Color(0xFFD3C6E2); // 비활성 버튼
  static const Color checkAvailable = Color(0xFF2E7D32); // 사용 가능 문구
  static const Color checkInProgress = Color(0xFF1565C0); // 확인 중 문구
  static const Color gray = Color(0xFF79747E); // 통신 중 버튼 배경
  static const Color cardBorder = Color(0xFFD9D3E1); // 평점 카드 테두리
  static const Color posterPlaceholder = Color(0xFFD8D2E0); // 포스터 대체 배경
  static const Color commentText = Color(0xFF655F6C); // 후기·등록일 글자
  static const Color entryBorder = Color(0xFFD6C9E8); // 마이페이지 진입 행 테두리
}
