import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_ratings.dart';
import 'submit_status.dart';

class MovieDetailViewModel extends ChangeNotifier {
  // ── ① 의존성 + 화면 데이터 ──
  MovieDetailViewModel(
    this._ratingService,
    this._auth,
    this._sessionRatings,
    this.movie,
  );

  final RatingApiService _ratingService;
  final AuthViewModel _auth; // 세션 번호 확인 + 401 시 세션 정리
  final SessionRatings _sessionRatings; // 등록 결과 보관
  final TmdbMovieDto movie;

  // ── ② 평점 등록 상태 ──
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  // ── ③ 평점 등록 (v7: memberId 없음, Authorization 헤더로 작성자 식별) ──
  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return; // 중복 제출 방지
    final version = _auth.sessionVersion; // 요청 시점 세션 번호
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      final rating = await _ratingService.createRating(
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      );
      // 화면이 닫혔어도 서버엔 저장됐으므로 보관소에는 반영한다 (세션 확인은 add 안에서)
      _sessionRatings.add(
        RatingWithMovie(rating: rating, movie: movie),
        version,
      );
      if (_disposed || version != _auth.sessionVersion) return;
      submitStatus = SubmitStatus.success;
    } catch (error) {
      if (_disposed || version != _auth.sessionVersion) return;
      submitStatus = SubmitStatus.error;
      submitMessage = ratingFailureMessage(error);
      // 401만 세션 정리. 403·409·400·네트워크는 안내만 하고 로그인 유지
      if (ratingFailureOf(error) == RatingFailure.sessionExpired) {
        await _auth.expireSession(version);
      }
    }

    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
