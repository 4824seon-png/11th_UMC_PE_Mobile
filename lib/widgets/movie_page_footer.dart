import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import 'movielog_button.dart';

// ── ① 목록 맨 아래: 더 보기 / 추가 로딩 / 재시도 / 끝 ──
class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({
    super.key,
    required this.vm,
    this.moreLabel = '더 보기', // 검색 화면은 '검색 결과 더 보기' (Essential 10)
    this.horizontalPadding = 16, // 영화 탭 Grid 16 / 검색 목록 24
  });

  final PagedMoviesViewModel vm;
  final String moreLabel;
  final double horizontalPadding;

  // Figma 3594-293·324: 14 Regular #655F6C
  static const _messageStyle = TextStyle(
    fontSize: 14,
    color: AppColors.commentText,
  );

  @override
  Widget build(BuildContext context) {
    // ── ② 끝 상태: 더 요청할 page가 없고, 로딩·오류도 없음 ──
    if (!vm.hasMore && !vm.isLoadingMore && vm.loadMoreError == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          '모든 영화를 확인했습니다.',
          textAlign: TextAlign.center,
          style: _messageStyle,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
      child: Column(
        children: [
          // ── ③ 다음 page 실패: 문구 + 같은 page 재시도 ──
          if (vm.loadMoreError != null) ...[
            Text(
              vm.loadMoreError!,
              textAlign: TextAlign.center,
              style: _messageStyle,
            ),
            const SizedBox(height: 19),
          ],
          // ── ④ 요청 중이면 회색 + spinner (MovieLogButton.isLoading) ──
          MovieLogButton(
            width: double.infinity,
            label: vm.loadMoreError == null ? moreLabel : '다음 페이지 다시 시도',
            isLoading: vm.isLoadingMore,
            onPressed: vm.phase == LoadPhase.ready ? vm.loadNextPage : null,
          ),
        ],
      ),
    );
  }
}
