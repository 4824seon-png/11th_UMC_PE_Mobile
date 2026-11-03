import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// 8px 간격 단위와 기본 모서리 반경 (디자인 시스템 기준)
  static const double radius = 8;

  static final ColorScheme _colorScheme =
      ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.onInverseSurface,
        outlineVariant: AppColors.outlineVariant,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.primary,
      );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 12),
      bodyMedium: TextStyle(fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      // 목록을 스크롤해도 AppBar 색이 변하지 않도록 (Figma: 고정 배경색)
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64, // Figma TopAppBar 높이
      // Figma W3-02·W3-04 화면 제목: Manrope Medium 22 / 행간 28
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 28 / 22,
        color: AppColors.primary,
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.secondaryContainer,
      side: BorderSide.none,
      shape: StadiumBorder(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        // onPressed가 null일 때(비활성) 디자인: 연보라 배경 + 흰 글자
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
        disabledForegroundColor: AppColors.onPrimary,
      ),
    ),
    // TextFormField 공통 스타일 (2주차 7번: 상태별 테두리)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 11.5,
      ),
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.inputHint),
      errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      enabledBorder: _inputBorder(AppColors.inputBorder), // 기본 상태
      focusedBorder: _inputBorder(AppColors.primary, width: 2), // 입력 중
      errorBorder: _inputBorder(_colorScheme.error), // 검증 실패
      // 검증 실패 + 입력 중
      focusedErrorBorder: _inputBorder(_colorScheme.error, width: 2),
    ),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
