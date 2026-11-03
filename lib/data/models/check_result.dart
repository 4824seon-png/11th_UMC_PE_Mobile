// 왜 값이 하나인데 모델을 사용하는가?
// 서버 응답은 json에서 온 Map<String, dynamic>이므로 key를 직접 다루는 곳이 많아진다
// 모델을 두면 key를 다루는 곳이 fromJson 한 곳으로 줄고
// 나머지 코드는 result.available처럼 타입이 정해진 값을 쓴다

// v5는 응답 body가 곧 결과
// 그래서 json['result']['available']이 아니라 json['available']을 읽는다

class CheckResult {
  const CheckResult({required this.available});
  // 즉 필드가 모드 final이므로 인스턴스 생성 후 바꿀 수 없는 값, const
  final bool available;
  // 서버 응답은 받은 뒤 바꿀 일이 없는 데이터
  factory CheckResult.fromJson(Map<String, dynamic> json) {
    // JSON 객체의 key는 항상 문자열이지만
    // value는 문자열·숫자·불리언·배열 등 여러 타입이 올 수 있다
    // 그래서 value 타입이 dynamic
    return CheckResult(available: json['available'] as bool);
    // json['available']의 타입은 dynamic이므로
    // CheckResult.available의 타입인 bool로 바꿔서 전달
  }
}
