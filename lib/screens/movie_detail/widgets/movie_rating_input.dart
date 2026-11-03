import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// 0.5점 단위로 별점을 입력받는 위젯.
/// 별점 값은 부모가 관리하고, 이 위젯은 입력만 담당한다.
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RatingBar.builder(
      initialRating: rating,
      minRating: 0.5,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 40,
      itemBuilder: (context, index) => Icon(Icons.star, color: colors.primary),
      onRatingUpdate: onChanged,
    );
  }
}
