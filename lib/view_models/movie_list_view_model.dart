import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/storage/genre_preference.dart';

/// 영화 탭의 로드 상태. idle은 ViewModel이 막 만들어져 아직 요청 전인 순간이다.
enum MovieListLoadStatus { idle, loading, success, empty, error }

/// 영화 탭(View)의 상태와 로직을 담당한다.
///
/// - 정책: Discover 결과를 TMDB id 기준 중복 없이 최대 [maxMovieCount]개
/// - 정책: 장르를 바꾸면 로컬 필터가 아니라 with_genres로 서버에 다시 요청
class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service, this._genrePreference);

  final TmdbMovieService _service;
  final GenrePreference _genrePreference;

  /// 영화 탭에 보여줄 최대 영화 수.
  static const maxMovieCount = 30;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// 장르 id → 이름. 카드 부제('2024 · SF')에 사용한다.
  Map<int, String> genreNames = const {};

  /// 선택한 장르 id. null = 전체 (with_genres를 보내지 않음).
  int? selectedGenreId;

  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message; // Error 상태에서 화면에 보여줄 문구

  // 요청마다 1씩 늘어나는 번호표. 응답이 도착했을 때 최신 요청인지 확인한다.
  int _requestVersion = 0;
  // 화면을 떠나 dispose된 뒤에는 notifyListeners를 부르지 않는다.
  bool _disposed = false;

  /// 로드 중인지. idle(요청 전)도 로드 중으로 본다.
  bool get isLoading =>
      status == MovieListLoadStatus.idle ||
      status == MovieListLoadStatus.loading;

  /// 처음 화면에 들어왔을 때: 장르 목록 → 저장된 장르 복원 → 영화 최대 30개.
  Future<void> loadInitial() async {
    final version = _startLoading();

    try {
      final fetchedGenres = await _service.fetchGenres();
      final restoredGenreId = await _restoreGenreId(fetchedGenres);
      if (_isStale(version)) return;

      genres = fetchedGenres;
      genreNames = {for (final genre in fetchedGenres) genre.id: genre.name};
      selectedGenreId = restoredGenreId;
      notifyListeners(); // 영화가 오기 전에 Chip 바(선택 상태 포함)를 먼저 보여준다.

      // 복원한 장르로 바로 조회한다. (전체 → 장르 순서의 이중 요청 없음)
      final result = await _fetchUpToThirtyMovies(genreId: restoredGenreId);
      if (_isStale(version)) return;
      _applyMovies(result);
    } on DioException catch (error) {
      if (_isStale(version)) return;
      _applyError('요청 실패: ${error.type.name}');
    } catch (error, stackTrace) {
      // DTO 변환 중 TypeError 등도 Error로 바꿔야 Loading에 멈추지 않는다.
      if (_isStale(version)) return;
      _applyError('변환 실패: $error', stackTrace);
    }

    if (_isStale(version)) return;
    notifyListeners();
  }

  Future<void> selectGenre(int? genreId) async {
    if (isLoading) return;
    // 이미 선택된 장르를 다시 누르면 다시 요청하지 않는다.
    if (genreId == selectedGenreId) return;

    selectedGenreId = genreId;
    // 저장은 목록 요청과 독립적이므로 기다리지 않는다. unawaited = "일부러 안 기다림"을 명시.
    unawaited(_saveGenreId(genreId));
    await _loadMovies();
  }

  /// Error 화면의 '다시 시도'.
  /// 장르 목록도 못 받았으면 처음부터, 받았으면 현재 선택한 장르로 영화만 다시 요청한다.
  Future<void> retry() => genres.isEmpty ? loadInitial() : _loadMovies();

  /// 현재 selectedGenreId로 영화 최대 30개를 page 1부터 다시 불러온다.
  Future<void> _loadMovies() async {
    final version = _startLoading();
    final genreId = selectedGenreId; // 요청 시점의 장르를 고정해 둔다.

    try {
      final result = await _fetchUpToThirtyMovies(genreId: genreId);
      if (_isStale(version)) return;
      _applyMovies(result);
    } on DioException catch (error) {
      if (_isStale(version)) return;
      _applyError('요청 실패: ${error.type.name}');
    } catch (error, stackTrace) {
      if (_isStale(version)) return;
      _applyError('변환 실패: $error', stackTrace);
    }

    if (_isStale(version)) return;
    notifyListeners();
  }

  Future<List<TmdbMovieDto>> _fetchUpToThirtyMovies({int? genreId}) async {
    final byId =
        <int, TmdbMovieDto>{}; // key = TMDB id → 같은 영화는 하나만 남는다 (순서 유지)
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovieCount && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == maxMovieCount) break;
      }

      // 마지막 페이지이거나 빈 페이지면 멈춘다. (빈 페이지 확인 = 무한 반복 방지)
      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    // 인증용: 실제 개수와 요청한 페이지 수를 남긴다.
    debugPrint(
      '[영화 목록] ${byId.length}개 (요청 ${pageNumber - 1}페이지, '
      '장르: ${genreId ?? '전체'})',
    );
    return byId.values.take(maxMovieCount).toList();
  }

  /// 요청 시작: 번호표를 발급하고 Loading을 알린다.
  int _startLoading() {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null; // 재시도할 때 이전 오류 문구를 지운다.
    notifyListeners();
    return version;
  }

  /// 이 응답을 버려야 하는지: 화면을 떠났거나, 더 새로운 요청이 시작됐다.
  bool _isStale(int version) => _disposed || version != _requestVersion;

  void _applyMovies(List<TmdbMovieDto> result) {
    movies = result;
    status = result.isEmpty
        ? MovieListLoadStatus.empty
        : MovieListLoadStatus.success;
  }

  void _applyError(String log, [StackTrace? stackTrace]) {
    debugPrint('[영화 목록] $log'); // 자세한 URL·status는 Interceptor 로그에 있다.
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    status = MovieListLoadStatus.error;
    message = selectedGenreId == null
        ? '영화를 불러오지 못했어요. 다시 시도해 주세요.'
        : '해당 장르 영화를 불러오지 못했어요. 다시 시도해 주세요.';
  }

  /// 저장된 장르 id를 읽는다. 지금 장르 목록에 없는 id면 전체(null)로 시작한다.
  Future<int?> _restoreGenreId(List<TmdbGenreDto> available) async {
    try {
      final savedId = await _genrePreference.read();
      if (savedId == null) return null;
      final exists = available.any((genre) => genre.id == savedId);
      return exists ? savedId : null;
    } catch (error) {
      // 복원 실패는 치명적이지 않다. 전체로 시작하고 로그만 남긴다.
      debugPrint('[영화 목록] 장르 복원 실패: $error');
      return null;
    }
  }

  Future<void> _saveGenreId(int? genreId) async {
    try {
      await _genrePreference.save(genreId);
    } catch (error) {
      // 저장 실패 시 다음 실행 때 전체로 보일 뿐이므로 화면은 그대로 둔다.
      debugPrint('[영화 목록] 장르 저장 실패: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++; // 진행 중이던 요청을 모두 "오래된 요청"으로 만든다.
    super.dispose();
  }
}
