import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

/// 프로필(닉네임) 수정 화면 전용 ViewModel.
/// 오류는 "어디에 보여줄지"로 나눈다: 입력 문제 → nicknameError(필드 아래), 그 외 → message(Snackbar)
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError;
  String? message;
  bool _disposed = false;

  /// 요청 전에 확인할 수 있는 규칙은 먼저 검사해 불필요한 통신을 줄인다.
  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  /// 입력을 고치기 시작하면 이전 오류 문구를 지운다. (입력값은 그대로)
  void clearNicknameError() {
    if (nicknameError == null) return;
    nicknameError = null;
    _notify();
  }

  /// 성공이면 true. 화면은 true일 때만 pop한다.
  Future<bool> save(String input) async {
    // 중복 탭 방지
    if (_disposed || status == EditProfileStatus.saving) {
      return false;
    }
    final current = _auth.member;
    if (_auth.status != AuthStatus.signedIn || current == null) return false;

    final version = _auth.sessionVersion; // 요청 시점 세션 번호
    final nickname = input.trim();
    message = null;
    nicknameError = validateNickname(nickname);
    if (nicknameError != null) {
      status = EditProfileStatus.failure;
      _notify();
      return false;
    }

    // 현재 닉네임과 같으면 요청 없이 완료 (자기 닉네임은 409 대상도 아니다)
    if (nickname == current.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    _notify();

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (!_isCurrent(version)) return false;
      _auth.updateMember(updated); // 응답이 최신 내 정보 → GET me 재호출 없음
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return false;
      status = EditProfileStatus.failure;
      // 토큰 무효·만료, 회원 없음 → 세션 정리. 안내는 로그인 화면 Snackbar가 한다.
      if (isSessionExpiredError(error) ||
          apiErrorCode(error) == 'MEMBER404_1') {
        await _auth.expireSession(version);
        return false;
      }
      switch (apiErrorCode(error)) {
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값 유지
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        default:
          message = '네트워크 상태를 확인하고 다시 시도해 주세요.'; // 로그아웃하지 않음
      }
    } catch (_) {
      if (!_isCurrent(version)) return false;
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요. 다시 시도해 주세요.';
    }

    _notify();
    return false;
  }

  // 화면이 닫혔거나 세션이 바뀌었으면 늦은 응답을 반영하지 않는다.
  bool _isCurrent(int version) =>
      !_disposed &&
      version == _auth.sessionVersion &&
      _auth.status == AuthStatus.signedIn;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
