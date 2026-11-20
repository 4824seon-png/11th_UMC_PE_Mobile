import 'package:dio/dio.dart';

import '../../data/storage/token_storage.dart';

/// 보호 API 요청에만 MovieLog JWT를 Bearer로 붙인다.
/// 토큰 값은 절대 로그로 남기지 않는다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final TokenStorage _storage;

  // 보호 대상: 워크북 서버의 /v7/members/me, /v7/ratings, /v7/ratings/{id}
  // 공개 조회 /v7/members/{memberId}/ratings는 여기에 해당하지 않는다.
  bool _isProtected(RequestOptions options) {
    final uri = options.uri;
    final path = uri.path;
    return uri.host == 'workbook.devnoco.com' &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
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
