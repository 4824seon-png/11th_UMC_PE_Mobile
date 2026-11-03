import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../view_models/my_ratings_view_model.dart';
import 'widgets/my_ratings_empty.dart';
import 'widgets/my_ratings_error.dart';
import 'widgets/my_ratings_list.dart';
import 'widgets/my_ratings_loading.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내가 등록한 평점'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      body: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MyRatingsLoadStatus.idle ||
            MyRatingsLoadStatus.loading => const MyRatingsLoading(),
            MyRatingsLoadStatus.empty => const MyRatingsEmpty(),
            MyRatingsLoadStatus.error => MyRatingsError(
              message: viewModel.message,
              onRetry: viewModel.load,
            ),
            MyRatingsLoadStatus.success => MyRatingsList(
              entries: viewModel.ratings,
              notice: viewModel.message,
            ),
          };
        },
      ),
    );
  }
}
