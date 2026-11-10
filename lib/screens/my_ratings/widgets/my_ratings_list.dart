import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/rating_with_movie.dart';
import '../../../data/models/rating_dto.dart';
import 'rating_card.dart';

class MyRatingsList extends StatelessWidget {
  const MyRatingsList({
    super.key,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
    this.notice,
  });

  final List<RatingWithMovie> entries;
  final ValueChanged<RatingDto> onEdit; // 어느 평점의 수정인지 RatingDto로 알린다
  final ValueChanged<RatingDto> onDelete;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final text = notice;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      children: [
        if (text != null) ...[
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.commentText),
          ),
          const SizedBox(height: 12),
        ],
        for (final (index, entry) in entries.indexed) ...[
          if (index > 0) const SizedBox(height: 18),
          RatingCard(
            entry: entry,
            onEdit: () => onEdit(entry.rating),
            onDelete: () => onDelete(entry.rating),
          ),
        ],
      ],
    );
  }
}
