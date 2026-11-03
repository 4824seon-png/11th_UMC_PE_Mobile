import 'package:dio/dio.dart';

import '../models/check_result.dart';

// Service는 HTTP 요청을 보내고 응답을 Dart 값으로 바꾸는 일만
// 저장하는 상태도 없어서 앱 전체에서 하나만 만들어 공유

class MemberCheckService {
  MemberCheckService(this._dio);
  // Service가 Dio를 직접 만들지 않고 생성자로 받는다 : 의존성 주입
  final Dio _dio;

  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    // 경로만 적는 이유 : 서버 주소를 Dio의 baseUrl에 한 번만 설정
    // Dio가 요청할 때 둘을 합친다. (baseUrl + path)
    // 주소가 바뀌어도 Client 한 곳만 수정

    // await는 응답이 올 때까지 이 함수의 실행을 멈추지만, 앱 화면은 멈추지 않는다
    // 정상 응답이면 다음 줄로 넘어가고, 통신 실패면 DioException이 던져져 다음 줄을 실행 x
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    // 호출하는 쪽에 필요한 것은 사용 가능 여부 하나이므로 .available만 꺼내 돌려준다.
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }
}
