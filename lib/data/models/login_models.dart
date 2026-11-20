/// POST /v7/auth/login 요청 body.
/// 비밀번호는 이 객체로 서버에 보내기만 하고 저장·출력하지 않는다.
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password, // 비밀번호는 공백도 의미가 있으므로 trim하지 않는다
  };
}

/// 로그인 성공 result. v7 명세상 memberId는 없다.
class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});

  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    nickname: json['nickname'] as String,
    accessToken: json['accessToken'] as String,
  );
}
