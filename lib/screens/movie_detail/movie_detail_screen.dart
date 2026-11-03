import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../widgets/tmdb_poster_image.dart';
import 'widgets/rating_dialog.dart';

/// 영화 상세 화면. 경로 /movies/:movieId
/// ShellRoute 밖에 있어서 NavigationBar가 표시되지 않는다.
///
/// 즐겨찾기 여부와 내가 남긴 평점을 화면 안에서 기억해야 하므로 StatefulWidget으로 만든다.
/// (평점·즐겨찾기는 화면 내부 상태로만 처리 → 상세를 나갔다 오면 초기화되는 것이 정상)
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  /// Path Parameter에서 읽은 TMDB 영화 id. 숫자가 아니면 null.
  final int? movieId;

  final TmdbMovieDto? movie;

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

  // ── 평점 남기기 (Dialog) ──
  Future<void> _openRatingDialog(int movieId) async {
    // 바깥 영역 탭·뒤로가기로 닫으면 값 없이 닫혀 null이 온다 → 반환 타입은 double?.
    final rating = await showDialog<double>(
      context: context,
      builder: (dialogContext) => RatingDialog(movieId: movieId),
    );

    // 취소했거나, 기다리는 동안 화면이 사라졌으면 이후 context를 쓰지 않는다.
    if (rating == null || !mounted) return;

    setState(() => _myRating = rating);
    _showSnackBar('$rating점을 남겼어요.');
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
    final movie = widget.movie;

    // URL의 id가 기준이다. extra가 없거나(딥링크·재시작) URL id와 다르면 표시하지 않는다.
    // 이 분기 이후로는 Dart가 movie를 non-null(TmdbMovieDto)로 취급한다(타입 승격).
    if (movie == null || movie.id != widget.movieId) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            '영화 정보를 찾을 수 없어요.\n목록에서 다시 선택해 주세요.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
        onRatingPressed: () => _openRatingDialog(movie.id),
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
  final VoidCallback onRatingPressed;

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
                label: Text(myRating == null ? '평점 남기기' : '내 평점 $myRating'),
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
