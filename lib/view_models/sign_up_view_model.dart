import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/sign_up_service.dart'; // ViewModel → Service 의존 방향
import '../data/models/create_member_request.dart';
import 'submit_status.dart';

// 중복 확인 상태를 다섯 값으로 고정
// enum은 한 번에 하나의 상태만
// bool 여러 개로 나타내면 isChecking과 isDuplicated가 동시에 참인 불가능한 조합이 생긴다.
enum CheckStatus { idle, checking, available, duplicated, error }

// version과 _requestVersion이 서로 다른 값이라는 점입니다.

// version은 요청을 보낼 때 받아 둔 내 번호 지역 변수라서 응답을 기다리는 동안 변하지 않는다.
// _requestVersion은 지금 유효한 최신 번호 입력이 바뀔 때마다 올라간다. 응답이 오면 version과 _requestVersion을 비교해, 내가 보낸 요청이 최신 요청인지 확인한다.

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final SignUpService _service;

  // 상태 필드
  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String? _duplicatedNickname;
  String _currentNickname = '';
  int _requestVersion = 0;
  bool _disposed = false;

  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String? _duplicatedEmail;
  String _currentEmail = '';
  int _emailRequestVersion = 0;

  // ── 가입 제출 상태 ──
  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId; // 가입 성공 응답에서 읽은 실제 ID
  String? passwordErrorText; // 서버 400(비밀번호 형식) → 비밀번호 입력칸 아래
  String? snackbarMessage; // 그 외 400·409 등 → Snackbar로 한 번 안내

  // 버튼을 누를 수 있는지
  bool get canCheckNickname =>
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  bool get isDuplicateCheckPassed =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  // 입력이 바뀔 때
  void onNicknameChanged(String value) {
    final trimmed = value.trim();
    _currentNickname = trimmed;
    _requestVersion++; // 이전 요청의 응답을 무효화합니다.
    if (_duplicatedNickname != null && trimmed == _duplicatedNickname) {
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }
    _clearSubmitError();
    if (!_disposed) notifyListeners();
  }

  // 요청 전 처리
  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    if (requested.isEmpty ||
        requested != _currentNickname ||
        !canCheckNickname) {
      return;
    }

    final version = ++_requestVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();

    // 정상 응답 처리
    try {
      final available = await _service.checkNickname(requested);
      if (_disposed ||
          version != _requestVersion ||
          _currentNickname != requested) {
        return;
      }
      nicknameCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      nicknameErrorText = available ? null : '이미 사용 중인 닉네임입니다.';
      if (!available) _duplicatedNickname = requested;
    } on DioException {
      // 통신 실패 처리
      if (_disposed ||
          version != _requestVersion ||
          _currentNickname != requested) {
        return;
      }
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  void onEmailChanged(String value) {
    final trimmed = value.trim();
    _currentEmail = trimmed;
    _emailRequestVersion++;
    if (_duplicatedEmail != null && trimmed == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }
    _clearSubmitError();
    if (!_disposed) notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    if (requested.isEmpty || requested != _currentEmail || !canCheckEmail) {
      return;
    }

    final version = ++_emailRequestVersion;
    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkEmail(requested);
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      emailCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';
      if (!available) _duplicatedEmail = requested;
    } on DioException {
      if (_disposed ||
          version != _emailRequestVersion ||
          _currentEmail != requested) {
        return;
      }
      emailCheckStatus = CheckStatus.error;
      emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _emailRequestVersion) notifyListeners();
  }

  // ── 가입 409 → 해당 입력칸을 '중복' 상태로 (6주차 중복 표시 규칙 재사용) ──
  void _markDuplicatedFromServer(CreateMemberRequest request, String message) {
    if (message.contains('이메일')) {
      _duplicatedEmail = request.email.trim();
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = message;
    } else if (message.contains('닉네임')) {
      _duplicatedNickname = request.nickname.trim();
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = message;
    }
  }

  // ── 입력이 바뀌면 이전 가입 실패(서버 오류)도 더 이상 현재 값의 결과가 아니다 ──
  void _clearSubmitError() {
    if (submitStatus == SubmitStatus.error) submitStatus = SubmitStatus.idle;
    snackbarMessage = null;
  }

  // ── 비밀번호를 고치기 시작하면 서버 오류 문구를 지운다 ──
  void onPasswordChanged() {
    passwordErrorText = null;
    notifyListeners();
  }

  // ── 회원가입 제출 ──
  Future<void> submit(CreateMemberRequest request) async {
    // ① 중복 제출 방지 + 이전 결과 초기화 + "제출 중" 알림
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      // ② 서버 요청 → 봉투에서 memberId 꺼내기
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');

      // ③ 성공 기록
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      // ④ 서버 실패: 비밀번호 형식 400이면 입력칸으로, 나머지는 Snackbar로
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      final statusCode = error.response?.statusCode;
      if (statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
        // 최종 중복(409): 서버가 알려준 항목을 '중복'으로 되돌려 같은 값 재제출을 막는다
        if (statusCode == 409) _markDuplicatedFromServer(request, message);
      }
    } on StateError {
      // ⑤ 201인데 memberId가 없음: 계약 오류 → 가입 완료로 표시하지 않음
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }

    // ⑥ 결과 알림 (화면이 이미 사라졌으면 하지 않음)
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}
