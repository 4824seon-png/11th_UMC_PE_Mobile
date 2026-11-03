import 'rating_dto.dart';
import 'tmdb_movie_dto.dart';

// 화면 카드 한 장에 필요한 데이터를 한 쌍으로 묶는다
class RatingWithMovie {
  const RatingWithMovie({required this.rating, this.movie});
  // 영화는 없을 수 있어서 선택 값
  final RatingDto rating;
  final TmdbMovieDto? movie;
  // fromJson이 없는 이유: 서버 응답을 그대로 옮긴 DTO가 아니라
  //앱에서 두 결과를 조합해 만드는 모델
}
