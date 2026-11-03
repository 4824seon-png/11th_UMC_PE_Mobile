import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

// 공용 위젯은 부모가 전달한 값을 기반으로 상태를 표시만 한다
// 통신 시작·종료 판단은 ViewModel이 하므로 StatelessWidget으로

class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.fontSize = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double fontSize;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: isLoading
              ? AppColors.gray
              : AppColors.buttonDisabled,
          foregroundColor: AppColors.onPrimary,
          disabledForegroundColor: AppColors.onPrimary,
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
