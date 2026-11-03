import 'package:flutter/material.dart';

/// 영화 목록을 불러오는 중(ConnectionState.waiting)에 보여주는 Loading 상태 화면.
/// 빈 화면 대신 진행 상태를 표시해 앱이 멈추지 않았음을 알린다.
class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
