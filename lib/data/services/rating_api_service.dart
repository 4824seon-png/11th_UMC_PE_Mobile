import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

// ── v7 응답 파서 ──

/// 등록(201)·수정(200) 봉투의 result = Rating 객체.
RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

/// 공개 유저별 조회는 봉투 없이 배열을 바로 준다.
List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

/// 평점 API. 메서드마다 공개/보호 Client를 골라 쓴다.
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio; // Interceptor 없음
  final Dio _authDio; // AuthInterceptor → Bearer

  /// [공개] 유저별 평점 조회. v7 로그인에는 memberId가 없어 이번 주 화면에서는 쓰지 않는다.
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _publicDio.get('/v8/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  /// [보호] 등록. body에 memberId 없음 — 서버가 토큰으로 작성자를 정한다.
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v8/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  /// [보호] 수정. PATCH지만 전체 교체 — comment를 빼면 null로 덮어써진다.
  /// 그래서 Dialog가 기존 값을 채워 열고, 항상 score·comment를 함께 보낸다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v8/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    return parseRatingResult(response.data);
  }

  /// [보호] 삭제. v7 성공은 204가 아니라 200 + result null.
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v8/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

// ── 평점 쓰기 실패 분류: code → "다음 행동" ──

enum RatingFailure {
  sessionExpired, // 세션 정리 → /login
  forbidden, // 남의 평점: 안내만
  notFound, // 이미 없는 평점: 안내 + 목록에서 제거
  duplicated, // 같은 영화 중복 등록: 안내만
  invalid, // 입력값 검증 실패: 서버 message
  unknown, // 네트워크·형식 오류: 재시도 안내
}

RatingFailure ratingFailureOf(Object error) {
  if (error is! DioException) return RatingFailure.unknown;
  if (isSessionExpiredError(error)) return RatingFailure.sessionExpired;
  return switch (apiErrorCode(error)) {
    // 토큰은 유효한데 회원이 없음 → 현재 세션을 더 쓸 수 없다
    'MEMBER404_1' => RatingFailure.sessionExpired,
    'RATING403_1' => RatingFailure.forbidden,
    'RATING404_1' => RatingFailure.notFound,
    'RATING409_1' => RatingFailure.duplicated,
    'COMMON400' => RatingFailure.invalid,
    _ => RatingFailure.unknown,
  };
}

String ratingFailureMessage(Object error) {
  return switch (ratingFailureOf(error)) {
    RatingFailure.sessionExpired => '로그인이 만료됐어요. 다시 로그인해 주세요.',
    RatingFailure.forbidden => '내가 작성한 평점만 수정·삭제할 수 있어요.',
    RatingFailure.notFound => '이미 삭제됐거나 존재하지 않는 평점이에요.',
    RatingFailure.duplicated => '이미 이 영화에 평점을 남겼어요.',
    RatingFailure.invalid =>
      (error is DioException ? apiErrorMessage(error) : null) ??
          '입력값을 확인해 주세요.',
    RatingFailure.unknown => '요청에 실패했어요. 잠시 후 다시 시도해 주세요.',
  };
}
