import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import 'tmdb_poster_image.dart';

/// TMDB 영화 한 편을 보여주는 카드.
/// 크기는 부모가 정한다(홈: SizedBox, 목록: Grid 칸).
/// 레이아웃·색은 Figma W3-02 "Article - Movie Item" 값을 따른다.
class TmdbMovieCard extends StatelessWidget {
  const TmdbMovieCard({super.key, required this.movie, this.genreName});

  /// 포스터 아래 텍스트 영역의 고정 높이. (간격 4 + 위 여백 8 + 제목 24 + 부제 24)
  static const double infoHeight = 60;

  final TmdbMovieDto movie;

  /// 부제에 표시할 장르 이름. 장르 목록을 모르는 화면(홈)에서는 null → 연도만 표시.
  final String? genreName;

  /// 'YYYY-MM-DD'에서 연도만 꺼낸다.
  /// TMDB는 개봉일이 없으면 null 또는 빈 문자열을 주므로 둘 다 '표시 안 함'으로 처리한다.
  String get _releaseYear {
    final date = movie.releaseDate;
    if (date == null || date.length < 4) return '';
    return date.substring(0, 4);
  }

  /// Figma 부제 형식 '2024 · SF'. ?genreName: null이면 리스트에 넣지 않는다.
  String get _subtitle =>
      [_releaseYear, ?genreName].where((text) => text.isNotEmpty).join(' · ');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest, // 이미지가 뜨기 전 자리 색
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      // 크기를 주지 않으면 Positioned.fill이 정한 영역을 채운다.
                      child: TmdbPosterImage(posterPath: movie.posterPath),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _RatingBadge(rating: movie.voteAverage),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 24 / 16,
              color: colors.onSurface,
            ),
          ),
          Opacity(
            opacity: 0.8,
            child: Text(
              _subtitle, // 비어 있어도 줄 높이는 유지되어 카드 정렬이 깨지지 않는다
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 포스터 오른쪽 위의 ★ 평점 뱃지. TMDB vote_average(10점 만점)를 그대로 표시한다.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: colors.inverseSurface.withValues(alpha: 0.8),
          child: Text(
            '★ ${rating.toStringAsFixed(1)}', // 8.471 → '8.5'
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 16 / 12,
              color: colors.onInverseSurface,
            ),
          ),
        ),
      ),
    );
  }
}
