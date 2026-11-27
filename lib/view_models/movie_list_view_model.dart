import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/storage/genre_preference.dart';

/// 영화 탭의 장르 상태 (목록·선택·저장).
/// 9주차: 영화 목록은 PagedMoviesViewModel이 page 단위로 담당한다.
class MovieListViewModel extends ChangeNotifier with SafeNotify {
  MovieListViewModel(this._service, this._genrePreference);

  final TmdbMovieService _service;
  final GenrePreference _genrePreference;

  List<TmdbGenreDto> genres = const [];

  /// 장르 id → 이름. 카드 부제('2024 · SF')에 사용한다.
  Map<int, String> genreNames = const {};

  /// 선택한 장르 id. null = 전체 (with_genres를 보내지 않음).
  int? selectedGenreId;

  // ── ① 장르 목록 → 저장된 장르 복원. 실패해도 '전체'로 진행 ──
  Future<int?> loadGenres() async {
    try {
      final fetchedGenres = await _service.fetchGenres();
      final restoredGenreId = await _restoreGenreId(fetchedGenres);
      if (isDisposed) return null;
      genres = fetchedGenres;
      genreNames = {for (final genre in fetchedGenres) genre.id: genre.name};
      selectedGenreId = restoredGenreId;
    } catch (error) {
      // 장르를 못 받아도 영화 목록은 '전체'로 볼 수 있다. Chip 바만 비어 있다.
      debugPrint('[영화 목록] 장르 조회 실패: $error');
    }
    notifyIfAlive();
    return selectedGenreId;
  }

  // ── ② 장르 선택: 바뀌었으면 true (화면이 첫 page를 다시 요청) ──
  bool selectGenre(int? genreId) {
    if (genreId == selectedGenreId) return false; // 같은 장르 재요청 방지
    selectedGenreId = genreId;
    // 저장은 목록 요청과 독립적이므로 기다리지 않는다.
    unawaited(_saveGenreId(genreId));
    notifyIfAlive();
    return true;
  }

  /// 저장된 장르 id를 읽는다. 지금 장르 목록에 없는 id면 전체(null)로 시작한다.
  Future<int?> _restoreGenreId(List<TmdbGenreDto> available) async {
    try {
      final savedId = await _genrePreference.read();
      if (savedId == null) return null;
      final exists = available.any((genre) => genre.id == savedId);
      return exists ? savedId : null;
    } catch (error) {
      debugPrint('[영화 목록] 장르 복원 실패: $error');
      return null;
    }
  }

  Future<void> _saveGenreId(int? genreId) async {
    try {
      await _genrePreference.save(genreId);
    } catch (error) {
      debugPrint('[영화 목록] 장르 저장 실패: $error');
    }
  }
}
