import 'package:flutter/material.dart';

/// TMDB의 poster_path로 포스터 이미지를 그린다.
///
/// URL 조합, null 처리, 로드 실패 처리를 화면마다 반복하지 않도록 한 곳에 모은다.
/// width·height를 주지 않으면 부모가 정한 크기(예: Positioned.fill)를 그대로 채운다.
class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    super.key,
    required this.posterPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  /// TMDB 응답의 poster_path. 예: '/mt6uZzy7DAsncHlGGzMsyNgLR6v.jpg' (없으면 null)
  final String? posterPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  static const _baseUrl = 'https://image.tmdb.org/t/p';

  // 이미지 너비 규격. w500이면 카드·히어로 모두 선명하고, original보다 훨씬 가볍다.
  static const _size = 'w500';

  /// 'https://image.tmdb.org/t/p' + '/w500' + '/abc.jpg'
  /// posterPath가 null이거나 빈 문자열이면 요청할 URL이 없으므로 null.
  String? get _imageUrl {
    final path = posterPath; // 로컬 변수로 옮겨야 null 체크 후 String으로 승격된다.
    if (path == null || path.isEmpty) return null;
    return '$_baseUrl/$_size$path';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;

    // 1) 포스터 경로가 없는 영화 → 요청하지 않고 바로 placeholder
    if (imageUrl == null) return _placeholder(context);

    // 2) 경로는 있지만 네트워크 오류·404로 실패 → errorBuilder가 placeholder로 대체
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Container에 alignment가 있으면 부모가 허용하는 크기까지 늘어난다.
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
