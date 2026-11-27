// ── ① 특정 영화의 즐겨찾기 여부 ──
class FavoriteCheckDto {
  const FavoriteCheckDto({required this.movieId, required this.isFavorite});

  // ── ② 응답에 movieId가 없어서 요청에 쓴 값을 인자로 받음 ──
  factory FavoriteCheckDto.fromJson(Object? json, {required int movieId}) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('FavoriteCheckDto must be a JSON object.');
    }
    // ── ③ bool이 아니면 실패 (null·"true" 문자열 방지) ──
    if (json['isFavorite'] is! bool) {
      throw const FormatException('isFavorite must be a boolean.');
    }
    return FavoriteCheckDto(
      movieId: movieId,
      isFavorite: json['isFavorite'] as bool,
    );
  }

  final int movieId;
  final bool isFavorite;
}
