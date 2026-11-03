import 'package:flutter/material.dart';

import '../../../data/models/tmdb_genre_dto.dart';

/// 가로로 스크롤되는 장르 Chip 바.
/// 선택 상태는 부모(ViewModel)가 가지고, 이 위젯은 표시와 선택 알림만 담당한다.
///
/// 크기·색은 Figma W3-02 "Section - Genre Filter Chips" 값을 따른다.
class GenreChipBar extends StatelessWidget {
  const GenreChipBar({
    super.key,
    required this.genres,
    required this.selectedGenreId,
    required this.enabled,
    required this.onSelected,
  });

  /// Genre API로 받은 장르 목록. 아직 받기 전이면 빈 목록 → '전체'만 표시.
  final List<TmdbGenreDto> genres;

  /// 선택한 장르 id. null = 전체.
  final int? selectedGenreId;

  /// false면 모든 Chip을 비활성화한다. (Discover 요청 중)
  final bool enabled;

  final ValueChanged<int?> onSelected;

  static const _allGenreLabel = '전체';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 가로 ListView는 세로 크기를 스스로 정하지 못하므로 SizedBox로 높이를 지정한다.
    return SizedBox(
      height: 40, // Figma 섹션 높이 (Chip 32px이 세로 가운데)
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16), // Figma 좌우 16
        itemCount: genres.length + 1, // 맨 앞 '전체' 1개 + TMDB 장르
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genreId = index == 0 ? null : genres[index - 1].id;
          final label = index == 0 ? _allGenreLabel : genres[index - 1].name;
          final isSelected = genreId == selectedGenreId;

          return Center(
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: enabled ? (_) => onSelected(genreId) : null,
              disabledColor: isSelected
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              showCheckmark: false, // 디자인: 체크 표시 없이 색으로만 구분
              // Figma: 좌우 16 · 상하 8 패딩 → 높이 32
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              labelPadding: EdgeInsets.zero,
              // 기본값은 터치 영역을 48px로 키워 Chip 바깥에 여백이 생긴다 → Figma 크기 그대로
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              shape: const StadiumBorder(), // Figma 반경 9999 (알약 모양)
              side: BorderSide.none,
              selectedColor: colors.primary, // #6750A4
              backgroundColor: colors.surfaceContainerHighest, // #E6E0E9
              // Figma: 선택된 Chip에만 그림자 (Y 1, 흐림 2, 검정 5%)
              elevation: 1,
              pressElevation: 1,
              shadowColor: Colors.transparent,
              selectedShadowColor: Colors.black.withValues(alpha: 0.05),
              surfaceTintColor: Colors.transparent, // M3 elevation 색조 변화 방지
              labelStyle: TextStyle(
                // Figma: Manrope Medium 12 / 행간 16
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
                // 선택 #FFFFFF / 미선택 #494551
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}
