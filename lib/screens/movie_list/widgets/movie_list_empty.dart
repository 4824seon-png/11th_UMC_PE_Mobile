import 'package:flutter/material.dart';

/// 불러오기는 성공했지만 보여줄 영화가 없을 때의 Empty 상태 화면.
/// 서버가 빈 목록을 준 경우와 장르 필터 결과가 빈 경우 모두 이 화면을 쓴다.
class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('조건에 맞는 영화가 없습니다.'));
  }
}
