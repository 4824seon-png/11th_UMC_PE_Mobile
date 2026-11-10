//서버로 보낼 평점 데이터의 모양과 별점 검사 규칙을 한곳에 모은 파일

// ── ① 서버 전송 전 안전장치: 1~5 정수인지 검사하고 int로 변환 ──
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    // 반올림한 값과 원래 값이 다르면 소수점이 있다는 뜻
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  // 잘못된 인자가 들어왔다고 즉시 멈추고 에러를 던져서 호출자에게 알린다
  return value.toInt();
}

class CreateRatingRequest {
  // ── ② 생성자: 영화 번호·별점은 필수, 코멘트는 선택 ──
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment, // 코멘트는 선택 입력
  });

  // ── ③ 필드 ──
  final int movieId;
  final int score;
  final String? comment;

  // ── ④ toJson: 코멘트가 비어 있으면 key 자체를 빼고 보낸다 ──
  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    // Map 리터럴 안에 if (조건) 'key': value를 쓰면 조건이 참일 때만 그 항목이 들어간다
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(), // 앞에서 comment != null는 확인했지만
    // 필드는 Dart가 null이 아니라고 자동으로 판단해 주지 않아서(타입 승격이 안 됨) 직접 !를 붙여 null이 아님을 알려 준다
  };
}
