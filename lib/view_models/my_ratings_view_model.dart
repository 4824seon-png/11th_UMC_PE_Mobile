import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_ratings.dart';

/// 내가 등록한 평점 화면. 목록은 SessionRatings(이번 세션 등록분)를 그대로 보여주고,
/// 이 ViewModel은 v7 PATCH/DELETE와 실패 처리만 담당한다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._auth, this._sessionRatings) {
    // 보관소가 바뀌면(등록·수정·삭제·세션 정리) 화면도 다시 그린다.
    _sessionRatings.addListener(_notify);
  }

  final RatingApiService _service;
  final AuthViewModel _auth;
  final SessionRatings _sessionRatings;
  bool _disposed = false;

  List<RatingWithMovie> get ratings => _sessionRatings.entries;

  // ── ① 수정: 성공 응답(최신 Rating)으로 카드 교체. GET 재조회 없음 ──
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final version = _auth.sessionVersion;
    try {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      _sessionRatings.replace(updated, version);
    } catch (error) {
      await _handleWriteError(error, ratingId, version);
    }
  }

  // ── ② 삭제: 200 성공이면 카드 제거 ──
  Future<void> deleteRating(int ratingId) async {
    final version = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
      _sessionRatings.remove(ratingId, version);
    } catch (error) {
      await _handleWriteError(error, ratingId, version);
    }
  }

  // ── ③ 실패 공통 처리: 다음 행동을 정한 뒤 Dialog에는 StateError(문구)로 알린다 ──
  Future<Never> _handleWriteError(
    Object error,
    int ratingId,
    int version,
  ) async {
    final message = ratingFailureMessage(error);
    switch (ratingFailureOf(error)) {
      case RatingFailure.sessionExpired:
        await _auth.expireSession(version); // → /login + 만료 Snackbar
      case RatingFailure.notFound:
        _sessionRatings.remove(ratingId, version); // 서버에 없으니 목록도 맞춘다
      case RatingFailure.forbidden ||
          RatingFailure.duplicated ||
          RatingFailure.invalid ||
          RatingFailure.unknown:
        break; // 안내만. 로그아웃하지 않는다
    }
    throw StateError(message);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionRatings.removeListener(_notify);
    super.dispose();
  }
}
