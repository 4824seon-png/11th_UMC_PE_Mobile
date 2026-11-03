import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../view_models/movie_list_view_model.dart';
import '../../widgets/movielog_app_bar.dart';
import 'widgets/genre_chip_bar.dart';
import 'widgets/movie_grid.dart';
import 'widgets/movie_list_empty.dart';
import 'widgets/movie_list_error.dart';
import 'widgets/movie_list_loading.dart';

/// 영화 탭 화면.
class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar는 상태와 무관 → Consumer 밖에 두어 다시 그리지 않는다.
      appBar: MovieLogAppBar(
        title: '영화',
        actions: [
          // Figma W3-02 오른쪽 위 검색 아이콘 (18px, #494551). 검색 기능은 이후 주차 범위.
          IconButton(
            tooltip: '검색',
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('검색 기능은 준비 중이에요.'))),
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
      // Chip 바와 목록 영역이 모두 ViewModel 상태에 따라 바뀌므로 함께 Consumer로 감싼다.
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8), // Figma: 본문 위 여백 8
              GenreChipBar(
                genres: viewModel.genres,
                selectedGenreId: viewModel.selectedGenreId,
                enabled: !viewModel.isLoading,
                // 콜백: 한 번만 호출하므로 watch가 아니라 read.
                onSelected: (genreId) =>
                    context.read<MovieListViewModel>().selectGenre(genreId),
              ),
              // Column 안의 GridView는 높이가 정해져야 한다 → 남은 높이를 전부 준다.
              Expanded(
                child: switch (viewModel.status) {
                  MovieListLoadStatus.idle ||
                  MovieListLoadStatus.loading => const MovieListLoading(),
                  MovieListLoadStatus.error => MovieListError(
                    message: viewModel.message,
                    onRetry: () => context.read<MovieListViewModel>().retry(),
                  ),
                  MovieListLoadStatus.empty => const MovieListEmpty(),
                  MovieListLoadStatus.success => MovieGrid(
                    movies: viewModel.movies,
                    genreNames: viewModel.genreNames,
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
