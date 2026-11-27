import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/favorite_list_item.dart';
import '../../../widgets/tmdb_poster_image.dart';

// ── ① 즐겨찾기 카드 (Figma 3594-155: 342×144, 테두리 1px) ──
class FavoriteCard extends StatelessWidget {
  const FavoriteCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRetry,
  });

  final FavoriteListItem item;
  final VoidCallback? onTap; // 영화 정보가 없으면 null → 탭 비활성
  final VoidCallback onRetry; // '정보 다시 불러오기'

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}.$month.$day';
  }

  @override
  Widget build(BuildContext context) {
    final movie = item.movie;
    final posterPath = movie?.posterPath;

    // ── ② Material + InkWell: 테두리 모양 그대로 탭 물결 효과 ──
    return Material(
      color: AppColors.cardFill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ③ 포스터 78×116: 정보가 없으면 placeholder 박스 ──
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: posterPath == null
                    ? Container(
                        width: 78,
                        height: 116,
                        color: AppColors.favoritePlaceholder,
                      )
                    : TmdbPosterImage(
                        posterPath: posterPath,
                        width: 78,
                        height: 116,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── ④ 제목 17 Bold: 실패하면 '영화 #movieId' ──
                      Text(
                        movie?.title ?? '영화 #${item.favorite.movieId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.labelText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 부제 12 Regular (Figma 예시 문구 대신 등록일을 표시)
                      Text(
                        movie == null
                            ? (item.errorMessage ?? '영화 정보를 불러오지 못했습니다.')
                            : '등록일 ${_formatDate(item.favorite.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.commentText,
                        ),
                      ),
                      const SizedBox(height: 13),
                      const Text(
                        '즐겨찾기한 영화',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      // ── ⑤ 부분 실패 카드에만 재조회 (12 Bold, 위 간격 5) ──
                      if (movie == null) ...[
                        const SizedBox(height: 5),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onRetry,
                          child: const Text(
                            '정보 다시 불러오기',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
