// ── ① 즐겨찾기 1건: 등록 응답과 목록 응답의 원소 ──
class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });

  // ── ② JSON 객체가 아니면 바로 실패 ──
  factory FavoriteResponseDto.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('FavoriteResponseDto must be a JSON object.');
    }
    return FavoriteResponseDto(
      // ── ③ 숫자는 num으로 받아 int로 ──
      favoriteId: (json['favoriteId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int favoriteId;
  final int movieId;
  final DateTime createdAt;
}
