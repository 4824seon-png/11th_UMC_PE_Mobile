import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';
import 'auth_view_model.dart';

// ── ① 상세 화면 하나의 즐겨찾기 상태 (with SafeNotify) ──
class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
    required this.auth,
  });

  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final AuthViewModel auth; // [워크북 추가] 401 세션 정리용

  // ── ② 버튼이 읽는 4가지 상태 + 첫 조회 성공 여부 ──
  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // ── ③ record: 요청 시점의 세션 번호 + 지금 요청해도 되는지 ──
  ({int generation, bool ok}) _snapshot() {
    final generation = sessionGuard.generation;
    return (
      generation: generation,
      ok: sessionGuard.isCurrent(generation, accountId) && !isDisposed,
    );
  }

  // ── ④ 진입 시 여부 조회 ──
  Future<void> load() async {
    if (isLoading || isSaving) return;
    final snap = _snapshot();
    if (!snap.ok) return;
    final authVersion = auth.sessionVersion; // [워크북 추가]
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }
      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
    } catch (error) {
      // ── ⑤ [워크북 추가] 만료·무효 토큰이면 현재 세션 한 번 정리 ──
      if (error is DioException && isSessionExpiredError(error)) {
        await auth.expireSession(authVersion);
        return;
      }
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      // ── ⑥ 응답·오류·finally 모두 같은 세션일 때만 반영 ──
      if (sessionGuard.isCurrent(snap.generation, accountId) && !isDisposed) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  // ── ⑦ 등록/해제: 서버 성공 확인 후에만 아이콘 변경 ──
  Future<void> toggle() async {
    if (isSaving || isLoading || !hasLoadedStatus) return;
    final snap = _snapshot();
    if (!snap.ok) return;
    final authVersion = auth.sessionVersion; // [워크북 추가]
    final before = isFavorite;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (before) {
        await favoriteApi.deleteFavorite(movieId: movieId);
        if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
          return;
        }
        isFavorite = false;
      } else {
        await favoriteApi.addFavorite(movieId: movieId);
        if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
          return;
        }
        isFavorite = true;
      }
    } on DioException catch (error) {
      // ── ⑧ [워크북 추가] 401(2/3/4) → 세션 정리 ──
      if (isSessionExpiredError(error)) {
        await auth.expireSession(authVersion);
        return;
      }
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }
      // ── ⑨ 409(이미 등록)·404(이미 해제) → 다시 보내지 않고 서버 값으로 맞춤 ──
      final code = apiErrorCode(error);
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        try {
          final synced = await favoriteApi.checkFavorite(movieId: movieId);
          if (!sessionGuard.isCurrent(snap.generation, accountId) ||
              isDisposed) {
            return;
          }
          isFavorite = synced.isFavorite;
          errorMessage = null;
        } catch (_) {
          if (!sessionGuard.isCurrent(snap.generation, accountId) ||
              isDisposed) {
            return;
          }
          isFavorite = before;
          errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
        }
      } else {
        // ── ⑩ 그 외 실패: 이전 아이콘 유지 ──
        isFavorite = before;
        errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
      }
    } catch (_) {
      if (!sessionGuard.isCurrent(snap.generation, accountId) || isDisposed) {
        return;
      }
      isFavorite = before;
      errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
    } finally {
      if (sessionGuard.isCurrent(snap.generation, accountId) && !isDisposed) {
        isSaving = false;
        notifyIfAlive();
      }
    }
  }
}
