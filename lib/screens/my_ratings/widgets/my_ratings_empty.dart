import 'package:flutter/material.dart';

class MyRatingsEmpty extends StatelessWidget {
  const MyRatingsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('등록된 평점이 없습니다'));
  }
}
