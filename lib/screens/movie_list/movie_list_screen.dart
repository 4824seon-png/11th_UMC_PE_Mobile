import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../view_models/load_phase.dart';
import '../../view_models/movie_list_view_model.dart';
import '../../view_models/paged_movies_view_model.dart';
import '../../widgets/movie_page_footer.dart';
import '../../widgets/movielog_app_bar.dart';
import 'widgets/genre_chip_bar.dart';
import 'widgets/movie_grid.dart';
import 'widgets/movie_list_empty.dart';
import 'widgets/movie_list_error.dart';
import 'widgets/movie_list_loading.dart';

/// 영화 탭 화면. 장르는 MovieListViewModel, 영화 page는 PagedMoviesViewModel.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  // ── ① 첫 frame 뒤: 장르 복원 → 그 장르로 첫 page ──
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final genres = context.read<MovieListViewModel>();
    final paged = context.read<PagedMoviesViewModel>();
    final genreId = await genres.loadGenres();
    if (!mounted) return;
    await paged.loadInitial(genreId: genreId);
  }

  // ── ② 장르 변경: 바뀌었을 때만 첫 page부터 (generation 증가) ──
  void _onGenreSelected(int? genreId) {
    final changed = context.read<MovieListViewModel>().selectGenre(genreId);
    if (changed) {
      context.read<PagedMoviesViewModel>().loadInitial(genreId: genreId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar는 상태와 무관 → Consumer 밖에 두어 다시 그리지 않는다.
      appBar: MovieLogAppBar(
        title: '영화',
        actions: [
          // ── ⑥ 검색 아이콘 → 검색 화면 (NavigationBar 없는 전체 화면) ──
          IconButton(
            tooltip: '검색',
            onPressed: () => context.push('/movies/search'),
            // search.svg는 24px 상자 안에 18px 크기의 돋보기가 그려져 있다.
            icon: SvgPicture.asset(
              'assets/icons/search.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      // ── ③ 두 ViewModel을 함께 구독 ──
      body: Consumer2<MovieListViewModel, PagedMoviesViewModel>(
        builder: (context, genres, paged, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8), // Figma: 본문 위 여백 8
              GenreChipBar(
                genres: genres.genres,
                selectedGenreId: genres.selectedGenreId,
                // ── ④ 로딩 중에도 변경 가능 (늦은 응답은 generation이 버림) ──
                enabled: true,
                onSelected: _onGenreSelected,
              ),
              // Column 안의 스크롤 영역은 높이가 정해져야 한다 → 남은 높이를 전부 준다.
              Expanded(
                // ── ⑤ 첫 조회 상태별 화면 ──
                child: switch (paged.phase) {
                  LoadPhase.idle ||
                  LoadPhase.loading => const MovieListLoading(),
                  LoadPhase.error => MovieListError(
                    message: paged.errorMessage,
                    onRetry: () =>
                        paged.loadInitial(genreId: genres.selectedGenreId),
                  ),
                  LoadPhase.empty => const MovieListEmpty(),
                  LoadPhase.ready => MovieGrid(
                    movies: paged.movies,
                    genreNames: genres.genreNames,
                    footer: MoviePageFooter(vm: paged),
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
