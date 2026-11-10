// 회원가입 요청 모델
// 보내는 항목: 이메일, 비밀번호, 닉네임

// 요청 모델과 응답 모델을 분리하는 이유
// 하나로 합치면 응답에는 비밀번호가 비어 있음, 요청에는 memberId가 비어 있음 처럼 반쯤 빈 객체가 생긴다.
// 나누면 각 클래스가 자기 방향의 데이터만 정확히 담을 수 있다.

class CreateMemberRequest {
  // ── ① 생성자: 화면 입력값 세 개를 받는다 ──
  const CreateMemberRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  // ── ② 필드: 서버로 보낼 값 ──
  final String email;
  final String password;
  final String nickname;

  // ── ③ toJson: Dart 객체 → 서버로 보낼 Map (보내기 전 정리 포함) ──
  // Dart 객체를 Map<String, dynamic>으로 바꾸면 Dio가 그 Map을 JSON 문자열로 바꿔 body에 담는다.
  // trim() : 공백 제거, null이 아닌 빈 문자열은 그대로 둔다. (서버가 허용하는지 확인 필요)
  // 이메일·닉네임 앞뒤 공백은 실수로 들어간 것이므로 지우고, 비밀번호는 공백도 허용할 수 있으므로 그대로 둔다.
  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
    'nickname': nickname.trim(),
  };
}
