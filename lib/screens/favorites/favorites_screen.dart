import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/tmdb_movie_dto.dart';
import '../../view_models/favorites_view_model.dart';
import '../../view_models/load_phase.dart';
import '../../widgets/movielog_button.dart';
import 'widgets/favorite_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  // ── ① 이동 방법은 Route가 정함 (화면은 '언제 끝났는지'만 기다림) ──
  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // ── ② 첫 frame 뒤 1회 조회 ──
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  // ── ③ 상세로 갔다가 돌아오면 다시 조회 ──
  Future<void> _open(FavoritesViewModel vm, TmdbMovieDto movie) async {
    await widget.onOpenMovie(movie); // 상세에서 pop될 때까지 대기
    if (!mounted) return;
    await vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 즐겨찾기'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      // ── ④ phase별로 다른 화면 ──
      body: Consumer<FavoritesViewModel>(
        builder: (context, vm, _) {
          switch (vm.phase) {
            case LoadPhase.idle:
            case LoadPhase.loading:
              return const Center(child: CircularProgressIndicator());

            case LoadPhase.empty:
              return const _FavoritesEmpty();

            case LoadPhase.error:
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Figma 3594-175: 16 Bold #655F6C → 버튼까지 28
                    Text(
                      vm.errorMessage ?? '즐겨찾기를 불러오지 못했습니다.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.commentText,
                      ),
                    ),
                    const SizedBox(height: 28),
                    MovieLogButton(
                      label: '다시 시도',
                      width: 222,
                      onPressed: vm.refresh,
                    ),
                  ],
                ),
              );

            case LoadPhase.ready:
              // ── ⑤ 당겨서 새로고침 + 카드 목록 ──
              return RefreshIndicator(
                onRefresh: vm.refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Figma 3594-155: 좌우 24, 카드 사이 19
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  itemCount: vm.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 19),
                  itemBuilder: (context, index) {
                    final item = vm.items[index];
                    final movie = item.movie;
                    return FavoriteCard(
                      item: item,
                      onTap: movie == null ? null : () => _open(vm, movie),
                      onRetry: vm.refresh,
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}

// ── ⑥ 빈 목록 안내 (Figma 3594-165: 북마크 아이콘 + 2줄) ──
class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border, size: 28, color: AppColors.primary),
          SizedBox(height: 32),
          // 17 Bold #655F6C → 부제까지 14
          Text(
            '아직 즐겨찾기한 영화가 없습니다.',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.commentText,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '영화 상세에서 북마크를 눌러보세요.',
            style: TextStyle(fontSize: 13, color: AppColors.commentText),
          ),
        ],
      ),
    );
  }
}
