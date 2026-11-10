// 쓰기 요청(가입·평점 등록)의 진행 상태. 한 번에 하나의 상태만 가진다.
enum SubmitStatus { idle, submitting, success, error }
