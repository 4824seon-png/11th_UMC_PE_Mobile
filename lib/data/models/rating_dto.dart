// 평점 한 건을 담는 모델
class RatingDto {
  const RatingDto({
    required this.ratingId,
    required this.movieId,
    required this.score,
    required this.comment,
    // 타입은 nullable이지만 required
    // 값이 null일 수는 있어도 전달은 해야 한다
    required this.createdAt,
  });
  final int ratingId; // 평점 고유 번호
  final int movieId;
  final int score; // 사용자가 준 평점(1~5)
  final String? comment; // 후기가 없을 수 있음을 타입에 표현 컴파일러가 null 처리를 강제
  final DateTime createdAt;

  factory RatingDto.fromJson(Map<String, dynamic> json) => RatingDto(
    ratingId: (json['ratingId'] as num).toInt(),
    movieId: (json['movieId'] as num).toInt(),
    score: (json['score'] as num).toInt(),
    comment: json['comment'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
