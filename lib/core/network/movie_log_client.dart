import 'package:dio/dio.dart';

import '../../data/storage/token_storage.dart';
import 'auth_interceptor.dart';

// 공개·보호 Client가 같은 서버 설정을 쓰도록 한곳에 둔다.
BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

// 공개 요청용: 로그인, 회원가입, 중복 확인, 유저별 평점 조회 / Interceptor 없음
Dio createMovieLogClient() {
  return Dio(_movieLogOptions());
}

// 보호 요청용: 내 정보, 평점 등록·수정·삭제 / AuthInterceptor 등록
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  return dio;
}
