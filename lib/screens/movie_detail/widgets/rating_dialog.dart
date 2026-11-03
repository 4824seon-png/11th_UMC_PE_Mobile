import 'package:flutter/material.dart';

import 'movie_rating_input.dart';

/// 별점을 입력받는 Dialog.
/// 어떤 영화의 평점인지 알 수 있도록 TMDB 영화 id(movieId)를 함께 받는다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, required this.movieId});

  /// TMDB 영화 id. 배열 index가 아니라 영화를 식별하는 값이다.
  final int movieId;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double rating = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '영화는 어떠셨나요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            MovieRatingInput(
              rating: rating,
              onChanged: (value) {
                setState(() {
                  rating = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: rating == 0
                  ? null
                  : () {
                      debugPrint(
                        '[평점] movieId=${widget.movieId}, score=$rating',
                      );
                      // 두 번째 인자가 showDialog<double>의 반환값이 된다.
                      Navigator.pop(context, rating);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
