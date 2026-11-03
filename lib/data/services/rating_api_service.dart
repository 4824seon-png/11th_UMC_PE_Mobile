import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

class RatingApiService {
  // 같은 서버를 쓰므로 client 하나 공유
  RatingApiService(this._dio);
  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    // 인자로 받은 회원의 공개 평점을 조회
    final response = await _dio.get('/v5/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
