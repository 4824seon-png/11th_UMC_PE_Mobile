// 공통 응답 모델

class CommonResponse<T> {
  // ── ① 생성자: 네 칸을 받아 객체를 만든다 ──
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result, // required 없음 : 실패 응답이나 수정 성공 응답에는 내용물이 없을 수 있다
  });

  // ── ② 필드: 서버 공통 봉투의 네 칸 ──
  final bool isSuccess;
  final String code; // 결과 코드 app의 다음 행동을 정함
  final String message; // 사람이 읽을 문장 화면에 그대로 보여준다.
  final T? result; // 실제 내용물 T : ① 내용물 종류가 API마다 다르므로 T, ② 없을 수 있으므로 ?
  // <T>(제네릭) 타입 자리를 비워 두고 쓸 때 채우는 문법

  // ── ③ fromJson: 서버 Map → CommonResponse 객체 ──
  // 새 객체를 만들어 돌려주는 특별한 생성자
  // 값이 아니라 함수를 매개변수로 받는다. Object? 하나를 받아서 T를 돌려주는 함수
  // 내용물이 회원 정보인지 아무것도 아닌지 모른다. 아는 쪽(호출하는 쪽)이 해석 방법을 함수로 넘겨준다. (역직렬화)
  factory CommonResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseResult,
  ) {
    // ③-1 내용물을 먼저 꺼내 둔다. null인지 확인한 다음 쓰기 위해
    final rawResult = json['result'];

    // ③-2 봉투 세 칸은 바로 읽고, 내용물은 있을 때만 해석을 맡긴다 : 내용물이 없으면 해석 함수를 부르지않음
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: rawResult == null ? null : parseResult(rawResult),
    );
  }
}
