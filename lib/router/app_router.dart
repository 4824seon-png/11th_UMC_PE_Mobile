import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/storage/genre_preference.dart';
import '../screens/home/home_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/movie_detail/movie_detail_loader.dart';
import '../screens/movie_list/movie_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/register/register_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../data/services/sign_up_service.dart';
import '../view_models/sign_up_view_model.dart';
import '../data/services/rating_api_service.dart';
import '../screens/my_ratings/my_ratings_screen.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/session_ratings.dart';
import '../screens/login/login_screen.dart';
import '../view_models/auth_view_model.dart';

import '../data/services/member_api_service.dart';
import '../screens/edit_profile/edit_profile_screen.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/movielog_button.dart';

/// 인증 상태와 현재 경로로 이동할 곳을 결정한다. null = 그대로 둔다.
/// 상태만 읽는 동기 함수. 여기서 API를 호출하지 않는다.
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도): 스플래시 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    // 로그인됨: 스플래시·로그인·회원가입은 홈으로
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

/// 앱의 모든 경로(URL)와 화면의 연결을 한 곳에서 관리한다.
class AppRouter {
  // private 생성자: 인스턴스를 만들지 않고 AppRouter.createRouter처럼 사용하는 네임스페이스 클래스.
  AppRouter._();
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  // 인스턴스를 받아야 refreshListenable에 연결할 수 있으므로 static final → 함수.
  // 호출은 _MovieLogRouterAppState.initState에서 한 번만 한다.
  static GoRouter createRouter(AuthViewModel authViewModel) => GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    refreshListenable: authViewModel, // 인증 상태가 바뀌면 redirect 재실행
    redirect: (context, state) =>
        authRedirect(authViewModel.status, state.uri.path),
    routes: [
      // ── ShellRoute 밖: NavigationBar가 없는 화면 ──
      GoRoute(
        path: '/start', // 스플래시: 세션 확인 중 / 실패 시 재시도
        builder: (context, state) {
          final auth = context.watch<AuthViewModel>();
          return SplashScreen(
            message: auth.message,
            onRetry: auth.status == AuthStatus.retryRequired
                ? auth.restoreSession
                : null,
          );
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
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
                        context.read<AuthViewModel>(),
                        context.read<SessionRatings>(),
                      ),
                      child: const MyRatingsScreen(),
                    ),
              ),
              GoRoute(
                path: 'profile/edit',
                parentNavigatorKey: rootNavigatorKey, // NavigationBar 없이 전체 화면
                builder: (context, state) {
                  final auth = context.watch<AuthViewModel>();
                  // 내 정보가 아직 없으면 (예: 딥링크 진입) 로딩/재시도
                  if (auth.member == null) {
                    return Scaffold(
                      appBar: AppBar(
                        centerTitle: true,
                        title: const Text('프로필 수정'),
                      ),
                      body: Center(
                        child: auth.memberStatus == MemberLoadStatus.error
                            ? MovieLogButton(
                                label: '다시 시도',
                                width: 160,
                                onPressed: () => auth.loadMember(force: true),
                              )
                            : const CircularProgressIndicator(),
                      ),
                    );
                  }
                  // 이 화면 전용 ViewModel → Route에서 생성 (화면을 나가면 dispose)
                  return ChangeNotifierProvider<EditProfileViewModel>(
                    create: (context) => EditProfileViewModel(
                      context.read<MemberApiService>(),
                      context.read<AuthViewModel>(),
                    ),
                    child: const EditProfileScreen(),
                  );
                },
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
          // ① URL 값은 항상 String → int로 변환. 숫자가 아니거나 1 미만이면 안내
          final id = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (id == null || id < 1) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('영화 ID가 올바르지 않습니다.')),
            );
          }

          // ② extra는 URL id와 같은 영화일 때만 사용 (아니면 Loader가 TMDB 조회)
          final extra = state.extra;
          return MovieDetailLoader(
            movieId: id,
            initialMovie: extra is TmdbMovieDto && extra.id == id
                ? extra
                : null,
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
