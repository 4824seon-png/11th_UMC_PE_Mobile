import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/tmdb_config.dart';
import 'tmdb_logging_interceptor.dart';

/// TMDB 전용 Dio Client를 만든다.
///
/// MovieLog 자체 API는 주소·인증 방식이 달라 Client를 따로 만든다.
/// (하나로 섞으면 자체 서버 요청에 TMDB Token이 실려 나갈 수 있다)
Dio createTmdbClient() {
  final dio = Dio(
    BaseOptions(
      // Service에서는 '/movie/popular'처럼 경로만 적는다.
      baseUrl: 'https://api.themoviedb.org/3',
      // 응답이 없을 때 무한히 기다리지 않고 DioException → Error 상태로 넘어가게 한다.
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        // Read Access Token은 Bearer 방식으로 헤더에 담는다. (.env에는 값만 저장)
        'Authorization': 'Bearer ${TmdbConfig.accessToken}',
        'accept': 'application/json',
      },
    ),
  );

  // 로그는 개발 중 확인용이므로 debug 빌드에서만 등록한다.
  if (kDebugMode) {
    dio.interceptors.add(TmdbLoggingInterceptor());
  }

  return dio;
}
