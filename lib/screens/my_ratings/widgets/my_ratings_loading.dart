import 'package:flutter/material.dart';

class MyRatingsLoading extends StatelessWidget {
  const MyRatingsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('평점을 불러오는 중'),
        ],
      ),
    );
  }
}
