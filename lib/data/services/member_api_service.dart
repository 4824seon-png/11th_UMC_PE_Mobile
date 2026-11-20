import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// 내 정보 API. 보호 Client를 주입받아 AuthInterceptor가 Bearer를 붙인다.
/// memberId를 path에 넣지 않는다 — 서버가 토큰으로 "누구인지" 판단한다.
class MemberApiService {
  MemberApiService(this._authDio);
  final Dio _authDio;

  Future<MemberInfo> fetchMe() async {
    final response = await _authDio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }

  /// 성공 응답이 곧 최신 내 정보다. 호출한 쪽은 GET me를 다시 부르지 않는다.
  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _authDio.patch(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
