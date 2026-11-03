import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/rating_with_movie.dart';
import '../../../widgets/tmdb_poster_image.dart';

class RatingCard extends StatelessWidget {
  const RatingCard({super.key, required this.entry});

  final RatingWithMovie entry;

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
        ],
      ),
    );
  }
}
