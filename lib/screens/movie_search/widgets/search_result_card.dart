import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/tmdb_movie_dto.dart';
import '../../../widgets/tmdb_poster_image.dart';

// ── ① 검색 결과 카드 (Figma 3594-352: 즐겨찾기 카드와 같은 342×144 테두리 카드) ──
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({super.key, required this.movie, required this.onTap});

  final TmdbMovieDto movie;
  final VoidCallback onTap;

  /// 'YYYY-MM-DD' → 'YYYY년 개봉'. 개봉일이 없으면 안내 문구.
  String get _releaseText {
    final date = movie.releaseDate;
    if (date == null || date.length < 4) return '개봉일 정보 없음';
    return '${date.substring(0, 4)}년 개봉';
  }

  @override
  Widget build(BuildContext context) {
    final posterPath = movie.posterPath;

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
              // ── ② 포스터 78×116: 포스터가 없는 영화는 placeholder ──
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
                      // 제목 17 Bold
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.labelText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 부제 12 Regular (Figma 예시 문구 대신 개봉 연도)
                      Text(
                        _releaseText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.commentText,
                        ),
                      ),
                      const SizedBox(height: 13),
                      // 3번째 줄 13 Bold primary (Figma 위치) → TMDB 평균 평점
                      Text(
                        '★ ${movie.voteAverage.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
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
