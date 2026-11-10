import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/rating_dto.dart';
import '../../widgets/movielog_button.dart';
import '../movie_detail/widgets/rating_dialog.dart';
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
              message: viewModel.refreshWarning ?? viewModel.message,
              onRetry: viewModel.load,
            ),
            MyRatingsLoadStatus.success => MyRatingsList(
              entries: viewModel.ratings,
              notice: viewModel.message,
              onEdit: (rating) => onEditPressed(context, rating),
              onDelete: (rating) => onDeletePressed(context, rating),
            ),
          };
        },
      ),
    );
  }
}

// ── 8-11 평점 수정: 기존 별점·코멘트로 채운 RatingDialog를 다시 연다 ──
Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => RatingDialog(
      initialScore: rating.score,
      initialComment: rating.comment, // null이면 TextField가 빈 칸으로 시작합니다.
      onSubmit: (score, comment) => viewModel.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      ),
    ),
  );
}

// ── 8-12 평점 삭제: 확인 Dialog → 삭제 중에는 Dialog 유지 ──
Future<void> onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => _DeleteRatingDialog(
      onConfirm: () => viewModel.deleteRating(rating.ratingId),
    ),
  );
  // 반환값은 실제로 삭제까지 마쳤을 때만 true입니다.
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  // ── ① 삭제 중 상태 ──
  bool _isDeleting = false;

  // ── ② 화면 (Figma 2506-169) ──
  @override
  Widget build(BuildContext context) {
    // ②-1 삭제 중에는 뒤로가기로 닫히지 않게
    return PopScope(
      canPop: !_isDeleting,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 36, 18, 37),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ②-2 제목 + 안내
              const Text(
                '평점을 삭제할까요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelText,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '삭제한 평점은 복구할 수 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.commentText),
              ),
              const SizedBox(height: 56),

              // ②-3 버튼: 취소(삭제 중 비활성) / 삭제(삭제 중 로딩)
              Row(
                children: [
                  Expanded(
                    child: MovieLogButton(
                      label: '취소',
                      backgroundColor: AppColors.secondaryButton,
                      foregroundColor: AppColors.primary,
                      onPressed: _isDeleting
                          ? null
                          : () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: MovieLogButton(
                      label: '삭제',
                      isLoading: _isDeleting,
                      onPressed: _isDeleting ? null : _onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ③ 삭제 실행: 성공이면 닫기 / 실패면 잠금 해제 + 서버 문구 Snackbar ──
  Future<void> _onConfirm() async {
    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      final text = error is StateError
          ? error.message
          : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }
}
