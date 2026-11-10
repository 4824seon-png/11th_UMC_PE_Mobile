import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

// 앱 공용 버튼. 누를 수 있음 / 비활성 / 로딩을 하나의 규칙으로
//그림. 상태 판단은 하지 않고 받은 값으로 표시만 함

// 공용 위젯은 부모가 전달한 값을 기반으로 상태를 표시만 한다
// 통신 시작·종료 판단은 ViewModel이 하므로 StatelessWidget으로

class MovieLogButton extends StatelessWidget {
  // ── ① 생성자: 7주차에 크기·모서리·색 옵션 추가 (기본값 = 6주차 모양) ──
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.fontSize = 14,
    this.height = 44,
    this.borderRadius = 12,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.onPrimary,
  });

  // ── ② 필드 ──
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double fontSize;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final Color foregroundColor;

  // ── ③ 비활성 판단: 로딩 중이거나 onPressed가 없으면 누를 수 없다 ──
  bool get _disabled => isLoading || onPressed == null;

  // ── ④ 화면: 옵션 값을 스타일에 연결 ──
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          // 크기는 SizedBox가 정하므로 기본 좌우 여백(24)을 없앤다. 좁은 버튼(63)에서 글자 줄바꿈 방지
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          disabledBackgroundColor: isLoading
              ? AppColors.gray
              : AppColors.buttonDisabled,
          foregroundColor: foregroundColor,
          disabledForegroundColor: AppColors.onPrimary,
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
