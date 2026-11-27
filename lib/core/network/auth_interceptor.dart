import 'package:dio/dio.dart';

import '../../data/storage/token_storage.dart';

/// 보호 API 요청에만 MovieLog JWT를 Bearer로 붙인다.
/// 토큰 값은 절대 로그로 남기지 않는다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final TokenStorage _storage;

  // ── ① 이 요청이 JWT를 붙일 보호 요청인지 판정 ──
  bool _isProtected(RequestOptions options) {
    // ── ② 다른 호스트(TMDB 등)에는 절대 JWT를 붙이지 않음 ──
    if (options.uri.host != 'workbook.devnoco.com') return false;
    final path = options.uri.path;
    final method = options.method.toUpperCase();

    // ── ③ 8주차 보호 경로를 v8로 ──
    final w8Protected =
        path == '/v8/members/me' ||
        path == '/v8/ratings' ||
        path.startsWith('/v8/ratings/');

    // ── ④ 즐겨찾기: 경로와 메서드를 함께 확인 ──
    final favorites =
        (path == '/v8/favorites' && (method == 'GET' || method == 'POST')) ||
        (RegExp(r'^/v8/favorites/[1-9]\d*$').hasMatch(path) &&
            (method == 'GET' || method == 'DELETE'));

    // ── ⑤ 영화 기록 저장 (Challenge 전용) ──
    final movieRecord = path == '/v8/movie-records' && method == 'POST';

    return w8Protected || favorites || movieRecord;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isProtected(options)) {
      handler.next(options);
      return;
    }
    // 이전 요청에 남은 헤더를 재사용하지 않고, 매번 저장소에서 최신 토큰을 읽는다.
    options.headers.remove('Authorization');
    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      // 토큰이 없으면 헤더 없이 보낸다 → 서버가 AUTH401_2로 응답한다.
      handler.next(options);
    } catch (_) {
      // 기기 저장소 실패는 서버 401과 다른 오류다. 세션 만료로 처리하지 않는다.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }
}
