import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/session/auth_session_bridge.dart';
import '../core/session/session_guard.dart';
import '../core/theme/app_theme.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/storage/token_storage.dart';
import '../router/app_router.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings.dart';
import '../data/services/favorite_api_service.dart';

/// 앱의 최상단 위젯. 앱 전역 의존성을 등록한다.
/// 객체는 build()가 아니라 Provider의 create에서 만든다 → rebuild돼도 한 번만 생성된다.
class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 토큰 저장소 (Keychain/Keystore)
        Provider<TokenStorage>(
          create: (_) => SecureTokenStorage(const FlutterSecureStorage()),
        ),

        // TMDB Client: MovieLog JWT를 절대 싣지 않는다.
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // ── 공개 Client (Interceptor 없음) ──
        Provider<SignUpService>(
          create: (_) => SignUpService(createMovieLogClient()),
        ),
        Provider<AuthApiService>(
          create: (_) => AuthApiService(createMovieLogClient()),
        ),
        // 유저별 조회(공개)와 등록·수정·삭제(보호)를 모두 맡으므로 두 Client를 받는다.
        Provider<RatingApiService>(
          create: (context) => RatingApiService(
            createMovieLogClient(),
            createAuthMovieLogClient(context.read<TokenStorage>()),
          ),
        ),
        // ── 보호 Client (AuthInterceptor 등록) ──
        Provider<MemberApiService>(
          create: (context) => MemberApiService(
            createAuthMovieLogClient(context.read<TokenStorage>()),
          ),
        ),
        // ── ① 즐겨찾기 Service: 보호 Client 주입 ──
        Provider<FavoriteApiService>(
          create: (context) => FavoriteApiService(
            createAuthMovieLogClient(context.read<TokenStorage>()),
          ),
        ),
        // Service를 주입받는 앱 전역 인증 상태
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),

        // 이번 세션 평점 보관소. AuthViewModel의 세션 변경을 구독해 스스로 비운다.
        ChangeNotifierProvider<SessionRatings>(
          create: (context) => SessionRatings(context.read<AuthViewModel>()),
        ),

        // ── ② AuthViewModel '아래'에 둬야 read할 수 있음 ──
        Provider<AuthSessionBridge>(
          create: (context) {
            final auth = context.read<AuthViewModel>();
            return AuthSessionBridge(
              authSignals: auth,
              sessionVersion: () => auth.sessionVersion,
              // signedIn이고 내 정보까지 확인된 뒤에만 email
              verifiedEmail: () => auth.status == AuthStatus.signedIn
                  ? auth.member?.email
                  : null,
            );
          },
          dispose: (_, bridge) => bridge.dispose(),
        ),
        // ── ③ 화면·ViewModel이 읽을 SessionGuard ──
        Provider<SessionGuard>(
          create: (context) => context.read<AuthSessionBridge>().guard,
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

/// GoRouter를 한 번만 만들고, 첫 frame 뒤 세션 복원을 시작하는 호스트.
class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(authViewModel);
    // build 도중 notifyListeners()가 불리지 않도록 첫 frame 이후에 시작한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authViewModel.restoreSession();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
