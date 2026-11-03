import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../view_models/movie_home_view_model.dart';
import '../../widgets/movielog_app_bar.dart';
import '../../widgets/tmdb_movie_card.dart';
import '../../widgets/tmdb_poster_image.dart';

/// 홈 탭 화면. MainScreen의 body(child)로 표시된다.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // 안쪽 Scaffold: AppBar 담당 (NavigationBar는 바깥 MainScreen이 담당).
    return Scaffold(
      appBar: const MovieLogAppBar(title: 'MovieLog'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 인사 문구는 상태와 무관 → Consumer 밖에 두어 상태가 바뀌어도 다시 그리지 않는다.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('오늘은 어떤\n영화를 볼까요?', style: textTheme.headlineSmall),
            ),
            const SizedBox(height: 24),
            Consumer<MovieHomeViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.status) {
                  MovieHomeLoadStatus.idle ||
                  MovieHomeLoadStatus.loading => const _HomeLoading(),
                  MovieHomeLoadStatus.error => _HomeMessage(
                    message: viewModel.message ?? '인기 영화를 불러오지 못했어요.',
                    // 버튼 콜백: 한 번만 호출하므로 watch가 아니라 read.
                    onRetry: () =>
                        context.read<MovieHomeViewModel>().loadPopular(),
                  ),
                  MovieHomeLoadStatus.empty => const _HomeMessage(
                    message: '표시할 인기 영화가 없어요.',
                  ),
                  MovieHomeLoadStatus.success => _PopularContent(
                    movies: viewModel.popularMovies,
                  ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Success 상태: 인기 1위 히어로 카드 + 인기 영화 가로 목록.
class _PopularContent extends StatelessWidget {
  const _PopularContent({required this.movies});

  final List<TmdbMovieDto> movies; // success 상태이므로 항상 1개 이상

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _HomeHeroCard(movie: movies.first),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SectionHeader(
            title: '인기 영화',
            onMorePressed: () => context.go('/movies'),
          ),
        ),
        const SizedBox(height: 12),
        _PopularMovieList(movies: movies),
      ],
    );
  }
}

/// 추천 영화 히어로 카드: 포스터 위에 그라데이션과 정보·버튼을 겹친다 (2주차 Stack/Positioned).
class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({required this.movie});

  final TmdbMovieDto movie;

  /// '2026 · ★ 8.5 / 10'. 개봉일이 없으면 연도는 생략한다.
  String get _subtitle {
    final date = movie.releaseDate;
    final rating = '★ ${movie.voteAverage.toStringAsFixed(1)} / 10';
    if (date == null || date.length < 4) return rating;
    return '${date.substring(0, 4)} · $rating';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TmdbPosterImage(posterPath: movie.posterPath),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '인기 1위',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/movies/${movie.id}', extra: movie),
                      icon: const Icon(Icons.info),
                      label: const Text('상세보기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 섹션 제목 + '전체보기 >' 버튼.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMorePressed});

  final String title;
  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(
          onPressed: onMorePressed,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text('전체보기'), Icon(Icons.chevron_right, size: 20)],
          ),
        ),
      ],
    );
  }
}

/// '인기 영화' 가로 스크롤 목록 (최대 5개).
class _PopularMovieList extends StatelessWidget {
  const _PopularMovieList({required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // 고정 숫자(5) 대신 실제 개수 → 5개보다 적게 와도 범위 오류가 없다.
        itemCount: movies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 150,
            child: TmdbMovieCard(movie: movies[index]),
          );
        },
      ),
    );
  }
}

/// Loading 상태: 히어로 카드 자리에 스피너.
class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Error·Empty 상태: 안내 문구 + (있으면) 다시 시도 버튼.
class _HomeMessage extends StatelessWidget {
  const _HomeMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry; // null이면 버튼을 그리지 않는다 (Empty)

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry; // 로컬 변수로 옮겨야 null 체크 후 타입 승격이 된다.

    return SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ],
        ),
      ),
    );
  }
}
