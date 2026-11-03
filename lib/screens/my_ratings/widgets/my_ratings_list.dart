import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/rating_with_movie.dart';
import 'rating_card.dart';

class MyRatingsList extends StatelessWidget {
  const MyRatingsList({super.key, required this.entries, this.notice});

  final List<RatingWithMovie> entries;
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
          RatingCard(entry: entry),
        ],
      ],
    );
  }
}
