import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import 'auth_view_model.dart';

/// 이번 로그인 세션에서 등록한 평점 보관소 (앱 전역).
///
/// v7에는 토큰 기반 "내 평점 전체 GET"이 없으므로, 등록 응답으로 받은 Rating만 모은다.
/// 세션이 바뀌면(로그아웃·만료·다른 계정·재시작) 자동으로 비운다.
/// → 재시작 뒤 이전 평점 복원은 API 계약 한계로 지원하지 않는다.
class SessionRatings extends ChangeNotifier {
  SessionRatings(this._auth) : _version = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  int _version; // 지금 보관 중인 목록이 속한 세션 번호
  final List<RatingWithMovie> _entries = []; // 최신 등록이 앞
  bool _disposed = false;

  List<RatingWithMovie> get entries => List.unmodifiable(_entries);

  /// 이 영화에 이번 세션에서 남긴 평점 (없으면 null)
  RatingWithMovie? findByMovieId(int movieId) {
    for (final entry in _entries) {
      if (entry.rating.movieId == movieId) return entry;
    }
    return null;
  }

  // 인증 상태가 바뀔 때마다 호출된다. 세션 번호가 바뀌었으면 이전 세션 목록을 비운다.
  void _onAuthChanged() {
    if (_auth.sessionVersion == _version) return;
    _version = _auth.sessionVersion;
    if (_entries.isEmpty) return;
    _entries.clear();
    _notify();
  }

  // 요청을 보낼 때 읽어 둔 번호가 지금 세션과 다르면 늦게 온 이전 세션 응답 → 버린다.
  bool _isCurrent(int requestVersion) =>
      !_disposed && requestVersion == _auth.sessionVersion;

  void add(RatingWithMovie entry, int requestVersion) {
    if (!_isCurrent(requestVersion)) return;
    _entries.insert(0, entry);
    _notify();
  }

  /// 수정 응답(최신 Rating)으로 교체한다. 영화 정보는 기존 것을 유지한다.
  void replace(RatingDto updated, int requestVersion) {
    if (!_isCurrent(requestVersion)) return;
    final index = _entries.indexWhere(
      (entry) => entry.rating.ratingId == updated.ratingId,
    );
    if (index < 0) return;
    _entries[index] = RatingWithMovie(
      rating: updated,
      movie: _entries[index].movie,
    );
    _notify();
  }

  void remove(int ratingId, int requestVersion) {
    if (!_isCurrent(requestVersion)) return;
    final before = _entries.length;
    _entries.removeWhere((entry) => entry.rating.ratingId == ratingId);
    if (_entries.length != before) _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
