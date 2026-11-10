import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../view_models/movie_detail_view_model.dart';
import '../../view_models/submit_status.dart';
import '../../widgets/tmdb_poster_image.dart';
import 'widgets/rating_dialog.dart';

// 영화 상세 화면. 「평점 남기기」를 누르면 Dialog를 열고 결과를 화면에 반영

/// 영화 상세 화면. 경로 /movies/:movieId
/// ShellRoute 밖에 있어서 NavigationBar가 표시되지 않는다.

/// 즐겨찾기 여부와 내가 남긴 평점을 화면 안에서 기억해야 하므로 StatefulWidget으로 만든다.
/// (평점·즐겨찾기는 화면 내부 상태로만 처리 → 상세를 나갔다 오면 초기화되는 것이 정상)
class MovieDetailScreen extends StatefulWidget {
  // 영화 데이터와 회원 번호는 MovieDetailViewModel(Loader가 제공)에서 읽는다.
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double? _myRating; // 아직 평점을 남기지 않았으면 null

  // ── Snackbar ──
  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    // 즐겨찾기를 빠르게 여러 번 누르면 메시지가 쌓이므로 현재 Snackbar를 먼저 닫는다.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ── 즐겨찾기 ──
  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showSnackBar(_isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.');
  }

  // ── 평점 남기기 (Dialog → 서버 등록) ──
  Future<void> _openRatingDialog() async {
    // ① 이 화면의 ViewModel (Dialog를 열기 전에 꺼내 둔다)
    final viewModel = context.read<MovieDetailViewModel>();
    int? savedScore;
    String? failedMessage; // 이번 Dialog에서 마지막으로 실패한 이유 (성공하면 지움)

    // ② Dialog: 확인 시 onSubmit 안에서 서버 등록 → 실패면 예외로 Dialog에 알림
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
      builder: (dialogContext) => RatingDialog(
        onSubmit: (score, comment) async {
          await viewModel.createRating(score: score, comment: comment);
          if (viewModel.submitStatus != SubmitStatus.success) {
            final reason = viewModel.submitMessage ?? '저장에 실패했습니다.';
            failedMessage = reason;
            throw StateError(reason);
          }
          failedMessage = null;
          savedScore = score;
        },
      ),
    );

    // ③ 화면이 살아 있을 때만. 저장하지 않고 닫혔다면 실패 이유가 있을 때만 안내
    if (!mounted) return;
    if (saved != true) {
      final reason = failedMessage;
      if (reason != null) _showSnackBar('평점을 등록하지 못했습니다. $reason');
      return;
    }

    // ④ 내 평점 표시 + 성공 Snackbar
    final score = savedScore;
    if (score != null) setState(() => _myRating = score.toDouble());
    _showSnackBar('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.');
  }

  // ── 공유 (BottomSheet) ──
  Future<void> _openShareSheet() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true, // 위·좌·우 시스템 영역(상태바 등)을 피한다
      showDragHandle: true, // 상단 손잡이 표시
      builder: (sheetContext) => const _ShareSheet(),
    );

    if (option == null || !mounted) return;

    // 시트가 닫힌 뒤, 시트의 context가 아닌 화면의 context로 Snackbar를 띄운다.
    _showSnackBar('$option 완료 (Mock)');
  }

  @override
  Widget build(BuildContext context) {
    // Loader가 준비한 영화와 학습용 회원 번호를 ViewModel에서 읽는다.
    final viewModel = context.read<MovieDetailViewModel>();
    final movie = viewModel.movie;
    final canRate = viewModel.memberId != null; // 가입 전이면 평점 버튼 비활성

    final myRating = _myRating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 상세'),
        actions: [
          IconButton(
            onPressed: _openShareSheet,
            icon: const Icon(Icons.share_outlined),
            tooltip: '공유',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 스크롤 안에서는 높이가 무한하므로 AspectRatio로 이미지 높이를 정한다.
            AspectRatio(
              aspectRatio: 3 / 4,
              child: TmdbPosterImage(posterPath: movie.posterPath),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _MovieInfo(movie: movie, myRating: myRating),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _Synopsis(text: movie.overview),
            ),
          ],
        ),
      ),
      // bottomNavigationBar = "하단 고정 영역". 본문 스크롤과 관계없이 버튼이 항상 보인다.
      bottomNavigationBar: _DetailActions(
        isFavorite: _isFavorite,
        myRating: myRating,
        onFavoritePressed: _toggleFavorite,
        onRatingPressed: canRate ? _openRatingDialog : null,
      ),
    );
  }
}

/// 제목·개봉 연도·평균 평점(10점)·(있으면) 내 평점(5점).
class _MovieInfo extends StatelessWidget {
  const _MovieInfo({required this.movie, required this.myRating});

  final TmdbMovieDto movie;
  final double? myRating;

  /// 'YYYY-MM-DD'에서 연도. 개봉일이 null·빈 문자열이면 null → 연도 줄을 그리지 않는다.
  String? get _releaseYear {
    final date = movie.releaseDate;
    if (date == null || date.length < 4) return null;
    return '${date.substring(0, 4)}년 개봉';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final myRating = this.myRating; // 로컬 변수로 옮겨야 null 체크 후 타입 승격이 된다.
    final releaseYear = _releaseYear;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(movie.title, style: textTheme.headlineSmall),
        if (releaseYear != null) ...[
          const SizedBox(height: 4),
          Text(
            releaseYear,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        // TMDB 평균 평점: 10점 만점
        _ReadOnlyRating(label: '평균', rating: movie.voteAverage, maxRating: 10),
        // 사용자가 Dialog로 남긴 평점: 5점 만점
        if (myRating != null) ...[
          const SizedBox(height: 8),
          _ReadOnlyRating(label: '내 평점', rating: myRating, maxRating: 5),
        ],
      ],
    );
  }
}

/// 읽기 전용 별점 한 줄: 라벨 + 별 5개 + '값 / 만점'.
class _ReadOnlyRating extends StatelessWidget {
  const _ReadOnlyRating({
    required this.label,
    required this.rating,
    required this.maxRating,
  });

  final String label;
  final double rating;
  final int maxRating; // 10(TMDB 평균) 또는 5(내 평점)

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        RatingBarIndicator(
          rating: rating / maxRating * 5, // 만점 기준 비율을 별 5개로 환산
          itemCount: 5,
          itemSize: 20,
          itemBuilder: (context, index) =>
              Icon(Icons.star, color: colors.primary),
        ),
        const SizedBox(width: 8),
        Text(
          '${rating.toStringAsFixed(1)} / $maxRating',
          style: textTheme.titleMedium,
        ),
      ],
    );
  }
}

/// 줄거리 제목 + 본문. TMDB overview가 빈 문자열이면 안내 문구를 가운데에 표시한다.
class _Synopsis extends StatelessWidget {
  const _Synopsis({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('줄거리', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        // TMDB는 줄거리가 없으면 null이 아니라 ""를 준다 → isEmpty로 확인한다.
        if (text.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '줄거리 정보가 없어요.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Text(text, style: textTheme.bodyLarge?.copyWith(height: 1.6)),
      ],
    );
  }
}

/// 하단 고정 버튼: 즐겨찾기 / 평점 남기기.
/// 상태(isFavorite, myRating)는 부모가 가지고, 이 위젯은 표시와 탭 알림만 담당한다.
class _DetailActions extends StatelessWidget {
  const _DetailActions({
    required this.isFavorite,
    required this.myRating,
    required this.onFavoritePressed,
    required this.onRatingPressed,
  });

  final bool isFavorite;
  final double? myRating;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onRatingPressed; // null이면 비활성 (가입 전)

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final myRating = this.myRating;

    // SafeArea: 하단 제스처 바(홈 인디케이터)에 버튼이 겹치지 않게 한다.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onFavoritePressed,
                icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
                label: const Text('즐겨찾기'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(color: colors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRatingPressed,
                icon: const Icon(Icons.rate_review_outlined),
                // 평점을 남긴 뒤에는 Dialog 반환값이 버튼 문구에 반영된다.
                label: Text(
                  onRatingPressed == null
                      ? '회원가입 후 평점 남기기'
                      : myRating == null
                      ? '평점 남기기'
                      : '내 평점 $myRating',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 공유 옵션 BottomSheet 내용 (Mock).
/// 항목을 누르면 선택한 옵션 이름을 돌려주며 시트를 닫는다.
class _ShareSheet extends StatelessWidget {
  const _ShareSheet();

  static const _options = [
    (icon: Icons.link, label: '링크 복사'),
    (icon: Icons.chat_bubble_outline, label: '카카오톡으로 공유'),
    (icon: Icons.sms_outlined, label: '메시지로 공유'),
  ];

  @override
  Widget build(BuildContext context) {
    // 하단 제스처 바 영역은 useSafeArea가 처리하지 않으므로 SafeArea로 직접 피한다.
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _options)
            ListTile(
              leading: Icon(option.icon),
              title: Text(option.label),
              onTap: () => Navigator.pop(context, option.label),
            ),
        ],
      ),
    );
  }
}
