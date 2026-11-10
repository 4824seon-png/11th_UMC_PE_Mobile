// Service가 중복 확인과 회원가입을 담당 : SignUpService
// 회원가입 화면에 필요한 API를 한 Service에 모아 두는 구조

import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

// Service는 HTTP 요청을 보내고 응답을 Dart 값으로 바꾸는 일만
// 저장하는 상태도 없어서 앱 전체에서 하나만 만들어 공유

// V5와 V6의 차이
// 쓸 수 있는 API 추가, 응답 구조 변경
// v5는 읽기 전용 서버였고, v6부터 쓰기가 생김
// v5: 성공하면 데이터를 그대로 줍니다.
// 예: { "available": true }, [ {...}, {...} ]
// v6: 새 API의 성공과 모든 실패를 이 봉투에 담아 줍니다.
// 예: { "isSuccess": true, "resultCode": 100, "resultMessage": "성공", "result": { "available": true } }, { "isSuccess": false, "resultCode": 201, "resultMessage": "이미 존재하는 이메일입니다." }
// 중복 확인 통과는 최종 확정이 아니다. 최종 판정은 가입 POST의 409
class SignUpService {
  SignUpService(this._dio);
  // Service가 Dio를 직접 만들지 않고 생성자로 받는다 : 의존성 주입
  final Dio _dio;

  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v6/members/nickname/$encoded');
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
    final response = await _dio.get('/v6/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  // ── ① 회원가입 POST: 요청 객체를 JSON body로 보내고, 공통 봉투로 받는다 ──
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    // ①-1 요청 보내기: path + body
    // get과 달리 post는 body를 가질 수 있고, 그 자리가 data
    final response = await _dio.post('/v6/members', data: request.toJson());

    // ①-2 응답 열기: 봉투는 CommonResponse가, 내용물은 SignUpResult가 해석
    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

// 실패 메시지 꺼내기
// ── 회원가입 실패 응답(봉투)에서 서버 message 꺼내기 ──
String writeSignUpErrorMessage(DioException error) {
  // ① 실패 응답 body (없을 수도 있음: 네트워크 끊김·타임아웃)
  final data = error.response?.data;
  // 네트워크가 끊기거나 타임아웃이면 response 자체가 null 그래서 ?.

  // ② body가 봉투(Map)면 열고, 아니면 null
  // so 서버 장애 시 HTML 문자열 같은 다른 모양이 와도 앱이 터지지 않음
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;

  // ③ 서버 문장을 우선 사용하고, 없으면 기본 문구
  return common?.message ?? '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
  // ??는 왼쪽이 null이면 오른쪽 값을 쓰라는 뜻. null 병합 연산자
}
