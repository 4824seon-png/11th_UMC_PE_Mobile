import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/storage/genre_preference.dart';
import '../screens/home/home_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/movie_detail/movie_detail_screen.dart';
import '../screens/movie_list/movie_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/register/register_screen.dart';
import '../screens/start/start_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../data/services/member_check_service.dart';
import '../view_models/sign_up_view_model.dart';
import '../data/services/rating_api_service.dart';
import '../screens/my_ratings/my_ratings_screen.dart';
import '../view_models/my_ratings_view_model.dart';

/// 앱의 모든 경로(URL)와 화면의 연결을 한 곳에서 관리한다.
class AppRouter {
  // private 생성자: 인스턴스를 만들지 않고 AppRouter.router처럼 사용하는 네임스페이스 클래스.
  AppRouter._();
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  // static final: 처음 접근할 때 한 번만 생성된다.
  // build 안에서 만들면 rebuild마다 새 라우터가 생겨 현재 위치가 초기화된다.
  static final router = GoRouter(
    // 앱 첫 화면. MaterialApp.home 대신 여기서 결정한다.
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      // ── ShellRoute 밖: NavigationBar가 없는 화면 ──
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              SignUpViewModel(context.read<MemberCheckService>()),
          child: const RegisterScreen(),
        ),
      ),

      // ── ShellRoute: 하위 route들에 MainScreen(NavigationBar)을 공통으로 씌운다 ──
      // builder의 child = 현재 URL에 매칭된 하위 화면(안쪽 Navigator).
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            // 선택된 탭 번호를 상태로 들고 있지 않고 URL에서 계산한다.
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => ChangeNotifierProvider(
              // 캐스케이드(..): 생성 직후 첫 요청을 보내고, create의 반환값은 ViewModel 자신
              create: (context) =>
                  MovieHomeViewModel(context.read<TmdbMovieService>())
                    ..loadPopular(),
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) => ChangeNotifierProvider(
              create: (context) => MovieListViewModel(
                context.read<TmdbMovieService>(),
                GenrePreference(),
              )..loadInitial(),
              child: const MovieListScreen(),
            ),
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    ChangeNotifierProvider<MyRatingsViewModel>(
                      create: (context) => MyRatingsViewModel(
                        context.read<RatingApiService>(),
                        context.read<TmdbMovieService>(),
                        sampleMemberId,
                      )..load(),
                      child: const MyRatingsScreen(),
                    ),
              ),
            ],
          ),
        ],
      ),

      // 상세 화면에는 NavigationBar가 없으므로 ShellRoute 밖에 둔다.
      // 탭 화면에서 push하면 루트 스택이 [MainScreen, MovieDetailScreen]이 되고,
      // pop하면 원래 탭으로 돌아간다.
      GoRoute(
        // ':movieId' = Path Parameter. 아래 pathParameters의 key와 철자가 같아야 한다.
        path: '/movies/:movieId',
        builder: (context, state) {
          final extra = state.extra;
          return MovieDetailScreen(
            // URL 값은 항상 String → int로 변환한다. 숫자가 아니면 null.
            movieId: int.tryParse(state.pathParameters['movieId'] ?? ''),
            movie: extra is TmdbMovieDto ? extra : null,
          );
        },
      ),
    ],
  );

  /// 현재 경로를 NavigationBar의 탭 번호로 변환한다.
  /// 순서는 MainScreen의 destinations 순서(홈 0, 영화 1, 마이 2)와 일치해야 한다.
  static int indexFromLocation(String path) {
    // == 대신 startsWith: '/movies/…' 같은 하위 경로도 영화 탭으로 본다.
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;

    return 0; // 기본값: 홈
  }
}
