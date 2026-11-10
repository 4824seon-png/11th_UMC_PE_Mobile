import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/theme/app_colors.dart';

/// 1점 단위(정수)로 별점을 입력받는 위젯.
/// 별점 값은 부모가 관리하고, 이 위젯은 입력만 담당한다.
class MovieRatingInput extends StatelessWidget {
  // ── ① 생성자: enabled가 추가됨 (저장 중 잠금용) ──
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true, // 저장 중에는 별점을 못 바꾸게 하려고 추가
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // ── ② 정수 모드 RatingBar ──
    return RatingBar(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: false,
      ignoreGestures: !enabled,
      itemCount: 5,
      itemSize: 35,
      glow: false,
      ratingWidget: RatingWidget(
        full: const Icon(Icons.star, color: AppColors.primary),
        half: const Icon(Icons.star_half, color: AppColors.primary),
        empty: const Icon(Icons.star_border, color: AppColors.primary),
      ),
      onRatingUpdate: onChanged,
    );
  }
}
