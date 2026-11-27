import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'load_phase.dart';

// ── ① 내 즐겨찾기 화면 상태 ──
class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.sessionGuard,
    required this.accountId,
    required this.auth,
    this.enrichmentConcurrency = 5,
  });

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final AuthViewModel auth; // [워크북 추가] 401 세션 정리용
  final int enrichmentConcurrency;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;
  // ── ② 이 화면 안에서의 요청 번호 (refresh 중복 대비) ──
  int _refreshGeneration = 0;

  Future<void> refresh() async {
    // ── ③ 세션 확인 + 번호 발급 ──
    final sessionGeneration = sessionGuard.generation;
    if (!sessionGuard.isCurrent(sessionGeneration, accountId) || isDisposed) {
      return;
    }
    final authVersion = auth.sessionVersion; // [워크북 추가]
    final refreshGeneration = ++_refreshGeneration;
    phase = LoadPhase.loading;
    errorMessage = null;
    notifyIfAlive();

    try {
      // ── ④ MovieLog: 내 즐겨찾기 (movieId 목록) ──
      final favorites = await favoriteApi.fetchMyFavorites();
      if (!sessionGuard.isCurrent(sessionGeneration, accountId) ||
          refreshGeneration != _refreshGeneration ||
          isDisposed) {
        return;
      }

      // ── ⑤ TMDB 보충: 최대 5개씩, 실패는 그 카드만 ──
      final enriched = await mapBounded(favorites, enrichmentConcurrency, (
        favorite,
      ) async {
        try {
          final movie = await tmdbApi.fetchMovieDetail(favorite.movieId);
          return FavoriteListItem(favorite: favorite, movie: movie);
        } catch (_) {
          return FavoriteListItem(
            favorite: favorite,
            errorMessage: '영화 정보를 불러오지 못했습니다.',
          );
        }
      });
      if (!sessionGuard.isCurrent(sessionGeneration, accountId) ||
          refreshGeneration != _refreshGeneration ||
          isDisposed) {
        return;
      }

      // ── ⑥ 결과 개수로 ready / empty 결정 ──
      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (error) {
      // ── ⑦ [워크북 추가] 만료·무효 토큰 → 세션 정리 ──
      if (error is DioException && isSessionExpiredError(error)) {
        await auth.expireSession(authVersion);
        return;
      }
      if (!sessionGuard.isCurrent(sessionGeneration, accountId) ||
          refreshGeneration != _refreshGeneration ||
          isDisposed) {
        return;
      }
      // ── ⑧ 목록 GET 자체가 실패 = 화면 전체 오류 ──
      phase = LoadPhase.error;
      errorMessage = '즐겨찾기를 불러오지 못했습니다.';
    } finally {
      if (sessionGuard.isCurrent(sessionGeneration, accountId) &&
          refreshGeneration == _refreshGeneration &&
          !isDisposed) {
        notifyIfAlive();
      }
    }
  }
}
