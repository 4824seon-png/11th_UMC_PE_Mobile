import 'package:flutter/material.dart';

import '../../../widgets/movielog_button.dart';

class MyRatingsError extends StatelessWidget {
  const MyRatingsError({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(height: 12),
            Text(message ?? '평점을 불러오지 못했습니다.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            MovieLogButton(label: '다시 시도', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
