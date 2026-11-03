import 'package:flutter/material.dart';

import '../../../data/models/tmdb_movie_dto.dart';
import '../../../widgets/tmdb_movie_card.dart';

/// 영화 목록을 2열 Grid로 보여준다.
/// 어떤 목록을 보여줄지는 부모가 정하고, 이 위젯은 그리기만 담당한다(Success 상태 화면).
class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    this.genreNames = const {},
  });

  final List<TmdbMovieDto> movies;

  /// 장르 id → 이름 (ViewModel.genreNames). 카드 부제 '2024 · SF'에 사용한다.
  final Map<int, String> genreNames;

  static const double _horizontalPadding = 16; // Figma 좌우 여백
  static const double _columnGap = 16; // Figma 열 간격
  static const double _rowGap = 24; // Figma 행 간격

  /// genreIds를 앞에서부터 확인해 이름을 아는 첫 장르를 돌려준다. 없으면 null.
  String? _firstGenreName(TmdbMovieDto movie) {
    for (final id in movie.genreIds) {
      final name = genreNames[id];
      if (name != null) return name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - _horizontalPadding * 2 - _columnGap) / 2;

        return GridView.builder(
          padding: const EdgeInsets.all(_horizontalPadding),
          itemCount: movies.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 한 줄에 2개
            crossAxisSpacing: _columnGap, // 좌우 간격
            mainAxisSpacing: _rowGap, // 위아래 간격
            mainAxisExtent: itemWidth * 1.5 + TmdbMovieCard.infoHeight,
          ),
          itemBuilder: (context, index) {
            final movie = movies[index];
            return TmdbMovieCard(
              movie: movie,
              genreName: _firstGenreName(movie),
            );
          },
        );
      },
    );
  }
}
