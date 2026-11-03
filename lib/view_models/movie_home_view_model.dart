import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

/// 홈 화면의 로드 상태. idle은 ViewModel이 막 만들어져 아직 요청 전인 순간이다.
enum MovieHomeLoadStatus { idle, loading, success, empty, error }

/// 홈 화면(View)의 상태와 로직을 담당한다.
///
/// - 상태: 인기 영화 목록, 로드 상태, 오류 문구
/// - 정책: Popular 1페이지 중 앞 [popularCount]개만 사용 (Service가 아니라 여기서 정한다)
class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  // 앱 전체가 공유하는 Service. 생성자로 받아(주입) 이 ViewModel이 직접 만들지 않는다.
  final TmdbMovieService _service;

  /// 홈에 보여줄 인기 영화 개수.
  static const popularCount = 5;

  List<TmdbMovieDto> popularMovies = const [];
  MovieHomeLoadStatus status = MovieHomeLoadStatus.idle;
  String? message; // Error 상태에서 화면에 보여줄 문구

  // 화면을 떠나 dispose된 뒤에 응답이 도착하면 notifyListeners를 부르지 않기 위한 표시.
  bool _disposed = false;

  Future<void> loadPopular() async {
    // 1) 요청 시작 → Loading을 먼저 화면에 알린다.
    status = MovieHomeLoadStatus.loading;
    message = null; // 재시도할 때 이전 오류 문구를 지운다.
    notifyListeners();

    try {
      // 2) Service는 1페이지(20개)를 그대로 준다.
      final page = await _service.fetchPopular();

      // 3) 화면 정책: 앞 5개만. take는 5개보다 적으면 있는 만큼만 돌려준다(RangeError 없음).
      popularMovies = page.results.take(popularCount).toList();
      status = popularMovies.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success;
    } on DioException catch (error) {
      // 401(Token 오류), 타임아웃, 네트워크 끊김 → 자세한 내용은 Interceptor 로그에 있다.
      debugPrint('[홈] 인기 영화 요청 실패: ${error.type.name}');
      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.';
    } catch (error, stackTrace) {
      // DioException이 아닌 오류(예: DTO 변환 중 TypeError)도 Error로 바꿔야
      // 화면이 Loading에 멈추지 않는다.
      debugPrint('[홈] 인기 영화 변환 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      status = MovieHomeLoadStatus.error;
      message = '인기 영화를 불러오지 못했어요.';
    }

    // 4) 기다리는 사이 화면을 떠났다면 알리지 않는다. (dispose 후 notify는 에러)
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
