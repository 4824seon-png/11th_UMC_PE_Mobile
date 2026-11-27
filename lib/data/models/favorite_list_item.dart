import 'favorite_response_dto.dart';
import 'tmdb_movie_dto.dart';

// ── ① 카드 1장 = MovieLog 즐겨찾기 + (있으면) TMDB 영화 ──
class FavoriteListItem {
  const FavoriteListItem({
    required this.favorite,
    this.movie,
    this.errorMessage,
  });

  final FavoriteResponseDto favorite; // 항상 있음 (MovieLog)
  final TmdbMovieDto? movie; // TMDB 조회 실패면 null
  final String? errorMessage;

  bool get hasMovie => movie != null;
}
