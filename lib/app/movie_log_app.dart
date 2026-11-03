import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../data/services/member_check_service.dart';
import '../data/services/rating_api_service.dart';

import '../core/network/tmdb_client.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../core/theme/app_theme.dart';

/// 앱의 최상단 위젯.

/// MaterialApp.router 바깥에 있어야 GoRouter가 만드는 모든 화면에서 context.read로 찾을 수 있다.
class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final movieLogClient = createMovieLogClient();

    return MultiProvider(
      providers: [
        // 상태 없는 Service는 앱 전체에서 1개를 공유한다.
        // 화면별 ViewModel은 여기가 아니라 각 Route(app_router.dart)에서 만든다.
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        Provider<MemberCheckService>(
          create: (_) => MemberCheckService(movieLogClient),
        ),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(movieLogClient),
        ),
      ],
      // MaterialApp.router: 앱 전역 설정(테마·제목)만 담당하고,
      // 어떤 화면을 보여줄지는 routerConfig로 넘긴 GoRouter가 결정한다.
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router, // static final → 앱 전체에서 라우터 1개 유지
      ),
    );
  }
}
