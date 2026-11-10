import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import '../models/common_response.dart';

// 반환 타입이 왜 모두 Future<void>인가
// 세 API 모두 성공했을 때 화면에 쓸 데이터를 주지 않거나, 줘도 믿을 수 없으므로, 성공 여부만 확인하고 화면은 상태를 직접 바꾸도록 한다.
// 실제 데이터는 성공 뒤 GET으로 다시 조회

// 매개변수가 { required ... }(이름 있는 매개변수)인 이유
// 순서로 넘기면 updateRating(42, 7, 5)처럼 무엇이 무엇인지 헷갈리고, 순서를 바꿔 넣어도 컴파일러가 잡지 못한다.
// 이름을 붙이면 updateRating(memberId: 42, ratingId: 7, score: 5)처럼 memberId와 ratingId를 섞을 수 없다.
class RatingApiService {
  // 같은 서버를 쓰므로 client 하나 공유
  RatingApiService(this._dio);
  final Dio _dio;

  // [인증 촬영용 · 비활성] 「저장 성공 후 GET만 실패 → GET 재시도」 재현용 스위치.
  // true면 다음 조회 GET 한 번을 실패시킨다. 다시 재현할 때만 주석을 풀어 사용한다.
  // static bool debugFailNextFetch = false;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    // [인증 촬영용 · 비활성] 스위치가 켜져 있으면 실제 요청 없이 DioException을 던진다.
    // if (debugFailNextFetch) {
    //   debugFailNextFetch = false;
    //   throw DioException(
    //     requestOptions: RequestOptions(path: '/v6/members/$memberId/ratings'),
    //     message: '인증 촬영용 임시 GET 실패',
    //   );
    // }
    // 인자로 받은 회원의 공개 평점을 조회
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── ① 등록 POST: body로 요청 객체를 보내고, 201이면 성공 ──
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    // 경로의 $memberId는 세션의 가입 번호, body의 movieId는 TMDB 영화 id 두 id의 출처가 다르다.
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // 201을 성공으로 처리합니다. result의 숫자/null 계약은 확인 전 파싱하지 않습니다.
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  // ── ② 수정 PATCH: score와 comment를 항상 함께 보낸다 ──

  // 등록처럼 CreateRatingRequest를 쓰지 않고 Map을 직접 만든다.
  // CreateRatingRequest.toJson()은 빈 코멘트를 생략하는데, 수정에서 생략하면 의도와 상관없이 후기가 지워지기 때문
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    // comment가 null이어도 key를 항상 넣어야 함
    // 코멘트 유지: Dialog가 기존 코멘트로 채워진 채 열림 → 그대로 확인 → 기존 문자열이 전송됨
    // 코멘트 삭제: 사용자가 입력창을 비움 → Dialog가 null로 바꿈 → "comment": null 전송
  }

  // ── ③ 삭제 DELETE: 204이면 성공, body는 읽지 않는다 ──
  // 204 No Content는 body가 비어 있다.
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

// ── 평점 쓰기 실패 응답(봉투)에서 서버 message 꺼내기 ──
String writeErrorMessage(DioException error) {
  final data = error.response?.data;
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;
  return common?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

// ── 이 오류 뒤에 목록을 다시 불러와야 하는가 (code로 다음 행동 결정) ──
bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map<String, dynamic> ? data['code'] as String? : null;
  // 403·404는 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해서 맞춥니다.
  return code == 'COMMON403' || code == 'COMMON404';
}
