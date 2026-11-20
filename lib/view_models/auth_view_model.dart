import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/storage/token_storage.dart';

/// 앱 전체 인증 상태. Router의 redirect가 이 값만 보고 화면을 결정한다.
enum AuthStatus {
  initializing, // 앱 시작: 저장소·GET me 확인 중 (Splash)
  signedOut, // 로그아웃 상태 (공개 화면만 허용)
  authenticating, // 로그인 요청 중
  signedIn, // 로그인됨
  retryRequired, // 세션 확인 실패(네트워크 등) → 토큰은 지우지 않고 재시도
}

/// 내 정보(GET me) 로드 상태. 인증 상태와 별개로 관리한다.
enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  // ── ① 화면이 읽는 상태 ──
  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? message; // 로그인 실패·세션 확인 실패 등 화면에 보여줄 문구
  bool sessionExpired = false; // 만료로 쫓겨났을 때만 true → 로그인 화면 Snackbar
  bool storageCleanupInProgress = false; // 토큰 삭제 중 (중복 정리·새 로그인 차단)

  // ── ② 내부 상태 ──
  int _sessionVersion = 0; // 세션이 바뀔 때마다 증가하는 번호표
  int get sessionVersion => _sessionVersion;
  bool _disposed = false;
  Future<void>? _tokenWrite; // 진행 중인 토큰 저장 (삭제가 저장을 앞지르지 않게)

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ── ③ 앱 시작 세션 복원: 토큰 존재 ≠ 로그인. GET me 성공 뒤에만 signedIn ──
  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _disposed) return;
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _notify();

    try {
      final token = await _storage.readAccessToken();
      if (!_isCurrent(version)) return;

      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut; // 저장된 토큰 없음 → 로그인 화면
      } else {
        final verifiedMember = await _memberApi.fetchMe(); // 서버 검증
        if (!_isCurrent(version)) return;
        member = verifiedMember;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      // 토큰 무효·만료, 또는 토큰은 유효한데 회원이 없음 → 재시도해도 소용없으므로 정리
      if (isSessionExpiredError(error) ||
          apiErrorCode(error) == 'MEMBER404_1') {
        await _clearCurrentSession(expired: true);
        return;
      }
      // 그 외(타임아웃·끊김·5xx): 토큰은 유지하고 재시도 화면
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      // 저장소 읽기 실패·응답 형식 오류
      status = AuthStatus.retryRequired;
      message = '인증 정보를 확인하지 못했어요. 다시 시도해 주세요.';
    }

    if (_isCurrent(version)) _notify();
  }

  // ── ④ 로그인: 성공 → 토큰 저장 → signedIn (내 정보는 MainScreen이 loadMember) ──
  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    final version = ++_sessionVersion;
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    _notify();

    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!_isCurrent(version)) return;

      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!_isCurrent(version)) return;

      status = AuthStatus.signedIn; // Router가 /home으로 보낸다
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = switch (apiErrorCode(error)) {
        'AUTH401_1' => '이메일 또는 비밀번호를 확인해 주세요.', // Form 오류. 만료 아님
        'COMMON400' => apiErrorMessage(error) ?? '입력값을 확인해 주세요.',
        _ => '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.',
      };
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 정보를 안전하게 저장하지 못했어요.';
    }

    _notify();
  }

  // ── ⑤ 내 정보 로드: 신규 로그인 후 MainScreen이 한 번 호출 ──
  Future<void> loadMember({bool force = false}) async {
    if (_disposed || status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return; // 중복 호출 방지
    if (member != null && !force) return; // 복원 때 이미 채웠으면 생략

    final version = _sessionVersion; // 세션을 바꾸는 작업이 아니므로 증가시키지 않는다
    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return; // 로그아웃·계정 전환 뒤 늦은 응답 무시
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionExpiredError(error) ||
          apiErrorCode(error) == 'MEMBER404_1') {
        await _clearCurrentSession(expired: true); // Router가 /login으로 이동
        return;
      }
      memberStatus = MemberLoadStatus.error; // 네트워크 실패: 로그아웃 없이 재시도 가능
      message = '내 정보를 불러오지 못했어요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    }

    _notify();
  }

  // ── ⑥ 프로필 수정 성공 응답으로 member 교체 (GET me 재호출 없음) ──
  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;
    member = updated;
    _notify();
  }

  // ── ⑦ 다른 ViewModel이 보호 요청에서 AUTH401_2/3/4를 받았을 때의 진입점 ──
  // 요청을 보낼 때 읽어 둔 sessionVersion을 넘긴다. 이미 세션이 바뀌었으면 무시.
  Future<void> expireSession(int requestVersion) async {
    if (requestVersion != _sessionVersion) return;
    await _clearCurrentSession(expired: true);
  }

  // ── ⑧ 사용자가 직접 누르는 로그아웃: 만료 Snackbar는 켜지 않는다 ──
  Future<void> logout() => _clearCurrentSession(expired: false);

  // ── ⑨ 로그인 화면이 만료 안내를 한 번 보여준 뒤 끈다 ──
  void consumeSessionExpired() {
    sessionExpired = false;
  }

  // ── ⑩ 현재 세션 정리: 번호표 증가 → 메모리 비움 → signedOut → 토큰 삭제 ──
  Future<void> _clearCurrentSession({required bool expired}) async {
    if (_disposed || storageCleanupInProgress) return; // 동시 401이어도 한 번만
    final version = ++_sessionVersion; // 진행 중이던 이전 세션 응답을 모두 무효화
    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut; // Router가 /login으로 보낸다
    message = null;
    _notify();

    try {
      // 진행 중인 토큰 저장이 있으면 끝난 뒤 지운다 (저장 실패여도 삭제는 시도)
      try {
        await _tokenWrite;
      } catch (_) {}
      await _storage.deleteAccessToken();
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 앱을 다시 실행해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify(); // 로그인 버튼 다시 활성화
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++; // 진행 중인 모든 응답을 오래된 것으로
    super.dispose();
  }
}
