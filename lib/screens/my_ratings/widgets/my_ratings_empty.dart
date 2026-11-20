import 'package:flutter/material.dart';

class MyRatingsEmpty extends StatelessWidget {
  const MyRatingsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '이번 로그인에서 등록한 평점이 없어요.\n영화 상세에서 평점을 남겨 보세요.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
