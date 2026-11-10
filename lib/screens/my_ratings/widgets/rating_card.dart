import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/rating_with_movie.dart';
import '../../../widgets/tmdb_poster_image.dart';
import '../../../widgets/movielog_button.dart';

class RatingCard extends StatelessWidget {
  const RatingCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final RatingWithMovie entry;
  final VoidCallback onEdit; // 수정 버튼 → 화면이 RatingDialog를 연다
  final VoidCallback onDelete; // 삭제 버튼 → 화면이 삭제 확인 Dialog를 연다

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}.$month.$day';
  }

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final posterPath = movie?.posterPath;
    final detail = rating.comment ?? (movie == null ? '포스터 정보 없음' : null);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: posterPath == null
                ? Container(
                    width: 82,
                    height: 124,
                    color: AppColors.posterPlaceholder,
                  )
                : TmdbPosterImage(
                    posterPath: posterPath,
                    width: 82,
                    height: 124,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 #${rating.movieId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.labelText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '별점 ${rating.score} / 5',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.commentText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '등록일 ${_formatDate(rating.createdAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.commentText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── 카드 오른쪽: 수정·삭제 버튼 (Figma 2506-80) ──
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                MovieLogButton(
                  label: '수정',
                  width: 63,
                  height: 35,
                  fontSize: 13,
                  borderRadius: 10,
                  backgroundColor: AppColors.secondaryButton,
                  foregroundColor: AppColors.primary,
                  onPressed: onEdit,
                ),
                const SizedBox(height: 8),
                MovieLogButton(
                  label: '삭제',
                  width: 63,
                  height: 35,
                  fontSize: 13,
                  borderRadius: 10,
                  backgroundColor: AppColors.dangerContainer,
                  foregroundColor: AppColors.danger,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
