import 'package:dio/dio.dart';

/// 실패 응답 봉투에서 code를 꺼낸다. 네트워크 끊김처럼 body가 없으면 null.
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final code = data['code'];
  return code is String ? code : null;
}

/// 실패 응답 봉투에서 서버 message를 꺼낸다. (COMMON400 입력 오류 표시용)
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return null;
  final message = data['message'];
  return message is String ? message : null;
}

/// 보호 요청의 토큰 없음(2)·무효(3)·만료(4).
/// 로그인 실패 AUTH401_1은 일부러 넣지 않는다 → Form 오류로만 처리.
/// 응답 body가 없는 경우(타임아웃·네트워크 끊김)나 HTML 오류 페이지를 받아도 앱이 멈추지 않도록, 서버가 보내는 code를 기준으로 판단한다.
const _sessionExpiredCodes = {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'};

bool isSessionExpiredError(DioException error) =>
    _sessionExpiredCodes.contains(apiErrorCode(error));
