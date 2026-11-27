import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/tmdb_movie_dto.dart';
import '../../view_models/load_phase.dart';
import '../../view_models/paged_movies_view_model.dart';
import '../../widgets/movie_page_footer.dart';
import '../../widgets/movielog_button.dart';
import 'widgets/search_result_card.dart';

/// 영화 검색 화면. 경로 /movies/search (NavigationBar 없음)
/// 영화 탭과 별도의 PagedMoviesViewModel 인스턴스를 사용한다.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key, required this.onOpenMovie});

  // ── ① 상세 이동 방법은 Route가 정함 ──
  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  // ── ② 입력값은 controller가, 마지막으로 제출한 검색어는 State가 보관 ──
  final _text = TextEditingController();
  String _submittedQuery = '';
  String? _inputError;

  // ── ③ 제출할 때만 요청. 빈 검색어는 서버에 보내지 않음 ──
  void _submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _inputError = '검색어를 입력합니다.');
      return;
    }
    FocusScope.of(context).unfocus(); // 키보드 닫기 (버튼으로 제출한 경우)
    setState(() {
      _inputError = null;
      _submittedQuery = query;
    });
    // 새 검색 = 새 조건 → generation 증가 + page 1부터
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
  }

  // ── ④ controller는 State가 만들었으므로 State가 정리 ──
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  static const _messageStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.commentText,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 검색'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── ⑤ 검색창 (Figma: 342×48, 흰 배경, 테두리 1px, 오른쪽 '검색') ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: TextField(
              controller: _text,
              textInputAction: TextInputAction.search, // 키보드 버튼 = 검색
              onSubmitted: _submitSearch,
              onChanged: (_) {
                if (_inputError != null) setState(() => _inputError = null);
              },
              style: const TextStyle(fontSize: 15, color: AppColors.labelText),
              decoration: InputDecoration(
                hintText: '영화 제목을 입력하세요',
                errorText: _inputError,
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: _border(AppColors.cardBorder),
                focusedBorder: _border(AppColors.primary),
                errorBorder: _border(AppColors.danger),
                focusedErrorBorder: _border(AppColors.danger),
                suffixIcon: TextButton(
                  onPressed: () => _submitSearch(_text.text),
                  child: const Text(
                    '검색',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9), // 검색창 → 첫 카드 25 (목록 위 여백 16 포함)
          // ── ⑥ 검색 상태별 화면 (idle ≠ empty) ──
          Expanded(
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, vm, _) {
                switch (vm.phase) {
                  case LoadPhase.idle:
                    return const Center(
                      child: Text('검색어를 입력합니다.', style: _messageStyle),
                    );
                  case LoadPhase.loading:
                    return const Center(child: CircularProgressIndicator());
                  case LoadPhase.error:
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            vm.errorMessage ?? '검색 결과를 불러오지 못했습니다.',
                            style: _messageStyle,
                          ),
                          const SizedBox(height: 28),
                          MovieLogButton(
                            label: '다시 시도',
                            width: 222,
                            onPressed: () =>
                                vm.loadInitial(query: _submittedQuery),
                          ),
                        ],
                      ),
                    );
                  case LoadPhase.empty:
                    return const Center(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.commentText,
                        ),
                      ),
                    );
                  case LoadPhase.ready:
                    // ── ⑦ 결과 카드 + 마지막 칸에 footer(검색 결과 더 보기) ──
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 16),
                      itemCount: vm.movies.length + 1,
                      itemBuilder: (context, index) {
                        if (index == vm.movies.length) {
                          return MoviePageFooter(
                            vm: vm,
                            moreLabel: '검색 결과 더 보기',
                            horizontalPadding: 24,
                          );
                        }
                        final movie = vm.movies[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 19),
                          child: SearchResultCard(
                            movie: movie,
                            onTap: () => widget.onOpenMovie(movie),
                          ),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
}
