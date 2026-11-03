import 'package:flutter/material.dart';

/// 모든 화면에서 재사용하는 공용 AppBar. 스타일은 AppBarTheme이 담당한다.
class MovieLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MovieLogAppBar({super.key, required this.title, this.actions});

  /// Figma TopAppBar 높이. AppBarTheme.toolbarHeight와 같아야 한다.
  static const double height = 64;

  final String title;

  /// 제목 오른쪽에 놓을 버튼들. 없으면 null (기존 화면은 그대로 동작).
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title),
    actions: actions,
    // Figma: 아이콘(18px)이 화면 오른쪽 끝에서 16px 안쪽.
    // IconButton은 48px 터치 영역 가운데에 아이콘을 두므로 아이콘 양옆에 15px씩 여백이 생긴다.
    // → 16 - 15 = 1px만 더 띄우면 Figma 위치와 같아진다.
    actionsPadding: const EdgeInsets.only(right: 1),
  );
}
