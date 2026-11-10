import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  String? refreshWarning; // 쓰기는 성공했지만 재조회(GET)가 실패했을 때의 안내

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    refreshWarning = null; // 새로 조회할 때마다 이전 안내를 지운다
    notifyListeners();
    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;
      final entries = <RatingWithMovie>[];
      var missingMovies = 0;
      // 같은 movieId는 캐시를 사용하고, 영화 조회 실패가 평점 목록을 지우지 않습니다.
      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] = await _movieService.findMovieById(
              rating.movieId,
            );
          } on DioException {
            // 일시적 네트워크 실패는 캐시하지 않습니다. 다음 로딩에서 재시도합니다.
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (_disposed || version != _requestVersion) return;
      ratings = entries;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  // ── ① 쓰기 성공 후 목록 재조회: GET 실패를 저장 실패로 바꾸지 않는다 ──
  // PATCH·DELETE가 성공한 순간 서버의 데이터는 이미 바뀌었으므로
  // GET 실패를 「저장 실패」로 보고하면, 사용자는 다시 저장 등록이라면 409, 삭제라면 404
  // 그래서 GET 실패는 예외로 던지지 않고 refreshWarning이라는 별도 상태
  Future<void> _refreshAfterWrite() async {
    // [인증 촬영용 · 비활성] 쓰기 직후 재조회 GET 한 번을 실패시키려면 주석을 푼다.
    // RatingApiService.debugFailNextFetch = true;
    await load(); // load()는 GET 실패를 status=error로 기록합니다.
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      notifyListeners();
    }
  }

  // ── ② 수정: PATCH 실패만 Dialog에 실패로 알리고, 성공이면 재조회 ──
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      // ②-1 서버 문구를 먼저 꺼내 두고, 403·404면 목록을 서버와 맞춘 뒤 Dialog에 실패를 알린다
      final errorMessage = writeErrorMessage(error);
      if (shouldRefreshAfterRatingError(error)) await load();
      throw StateError(errorMessage);
    }
    // ②-2 쓰기 성공. GET 실패는 다시 던지지 않는다
    await _refreshAfterWrite();
  }

  // ── ③ 삭제: DELETE 실패만 Dialog에 실패로 알리고, 성공이면 재조회 ──
  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      final errorMessage = writeErrorMessage(error);
      if (shouldRefreshAfterRatingError(error)) await load();
      throw StateError(errorMessage);
    }
    await _refreshAfterWrite();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
