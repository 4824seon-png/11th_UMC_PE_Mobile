// 회원가입 응답 모델
// 받는 항목: memberId, 이메일, 닉네임

class SignUpResult {
  // ── ① 생성자 ──
  const SignUpResult({
    required this.memberId,
    required this.email,
    required this.nickname,
  });

  // ── ② 필드: 봉투 안 result에 들어 있는 회원 정보 ──
  final int memberId;
  final String email;
  final String nickname;

  // ── ③ fromJson: result Map → SignUpResult 객체 ──
  // 봉투 전체가 아니라 result 안쪽만 표현, 봉투는 CommonResponse가 맡으므로 여기에 isSuccess나 result 필드를 또 두지 않는다.
  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    return SignUpResult(
      memberId: (json['memberId'] as num)
          .toInt(), // json int & double 모두 num으로 들어오므로 toInt()로 변환
      email: json['email'] as String,
      nickname: json['nickname'] as String,
    );
  }
}
