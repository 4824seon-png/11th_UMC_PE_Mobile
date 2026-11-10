import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../data/services/rating_api_service.dart';
import '../../data/services/tmdb_movie_service.dart';
import '../../view_models/learning_member_session.dart';
import '../../view_models/movie_detail_view_model.dart';
import 'movie_detail_screen.dart';

/// 영화 상세의 시작점. 영화 데이터를 준비한 뒤 ViewModel과 화면을 만든다.
class MovieDetailLoader extends StatefulWidget {
  // ── ① URL의 영화 id + (있으면) 목록에서 넘겨받은 영화 ──
  const MovieDetailLoader({
    // 영화 준비는 Loader가, 영화 표시와 등록은 Screen이 맡는다.
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  final int movieId;
  final TmdbMovieDto? initialMovie;

  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  // ── ② 영화 Future: initState에서 한 번만 만든다 ──
  late final Future<TmdbMovieDto> _movieFuture;

  @override
  void initState() {
    super.initState();
    _movieFuture = widget.initialMovie != null
        ? Future.value(widget.initialMovie!)
        : context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  }

  // ── ③ Future 상태에 따라: 로딩 / 실패 / 성공(ViewModel 제공) ──
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbMovieDto>(
      future: _movieFuture, // build마다 새 Future를 만들지 않습니다.
      builder: (context, snapshot) {
        // ③-1 로딩
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        // ③-2 실패
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('영화를 불러오지 못했습니다.')),
          );
        }
        // ③-3 성공: 이 화면 전용 ViewModel을 만들어 아래에 제공
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) => MovieDetailViewModel(
            context.read<RatingApiService>(),
            context.read<LearningMemberSession>().memberId,
            snapshot.data!,
          ),
          child: const MovieDetailScreen(),
        );
      },
    );
  }
}
