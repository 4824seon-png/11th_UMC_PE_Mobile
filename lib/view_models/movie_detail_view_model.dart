import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import 'submit_status.dart';

class MovieDetailViewModel extends ChangeNotifier {
  // ── ① 의존성 + 화면 데이터 (생성 시점에 정해짐) ──
  MovieDetailViewModel(this._ratingService, this.memberId, this.movie);
  final RatingApiService _ratingService;
  final int? memberId; // 학습용 현재 회원. 로그인 인증은 아닙니다.
  final TmdbMovieDto movie;

  // ── ② 평점 등록 상태 ──
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  // ── ③ 평점 등록 ──
  Future<void> createRating({required int score, String? comment}) async {
    // ③-1 가입 전이면 요청하지 않는다
    final id = memberId;
    if (id == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해 주세요.';
      notifyListeners();
      return;
    }

    // ③-2 중복 제출 방지 + 제출 중 알림
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();

    try {
      // ③-3 서버 등록: 경로는 세션 memberId, body의 movieId는 TMDB 영화 id
      await _ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      // ③-4 서버 실패 (400 별점 범위 / 404 유저 없음 / 409 중복 등록)
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = writeErrorMessage(error);
    } on StateError catch (error) {
      // ③-5 201이 아닌 성공 응답 (계약과 다름)
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = error.message;
    }

    // ③-6 결과 알림
    if (!_disposed) notifyListeners();
  }

  // ── ④ 정리 ──
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
