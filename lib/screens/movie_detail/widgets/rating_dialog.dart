import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/rating_request.dart';
import '../../../widgets/movielog_button.dart';
import 'movie_rating_input.dart';

/// 별점 + 코멘트를 입력받고, 확인 시 onSubmit(저장)을 Dialog 안에서 실행한다.
/// 등록(영화 상세)과 수정(내가 등록한 평점)에서 함께 사용한다.
class RatingDialog extends StatefulWidget {
  // ── ① 외부에서 받는 값: 초기값(수정용)과 저장 콜백 ──
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });

  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  // ── ② Dialog 내부 상태 ──
  // _score, _commentController, _isSubmitting, _errorText. 화면은 이 4개 값으로만 결정됨
  late int _score = widget.initialScore;
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorText;

  // ── ③ 정리: dispose Controller 해제 ──
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ── ④ 화면 ──
  // 4개 상태값을 화면으로 그림 (제목, 별, 라벨, 입력창, 오류, 버튼)
  @override
  Widget build(BuildContext context) {
    // ④-1 저장 중에는 뒤로가기로 닫히지 않게
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 33, 17, 38),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ④-2 제목
              const Text(
                '평점을 남겨주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelText,
                ),
              ),
              const SizedBox(height: 14),

              // ④-3 별점: 탭한 값을 정수로 검사해 _score에 저장
              Center(
                child: MovieRatingInput(
                  rating: _score.toDouble(),
                  enabled: !_isSubmitting,
                  onChanged: (value) =>
                      setState(() => _score = validateServerScore(value)),
                ),
              ),
              const SizedBox(height: 27),

              // ④-4 코멘트 라벨 + 입력창
              const Padding(
                padding: EdgeInsets.only(left: 3),
                child: Text(
                  '코멘트 (선택, 최대 500자)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.commentText,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: _commentController,
                enabled: !_isSubmitting,
                minLines: 4,
                maxLines: 4,
                maxLength: 500,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.labelText,
                ),
                decoration: InputDecoration(
                  hintText: '이 영화의 인상적인 장면은...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.commentText,
                  ),
                  counterText: '',
                  fillColor: AppColors.dialogInputFill,
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: _inputBorder(AppColors.dialogInputBorder),
                  disabledBorder: _inputBorder(AppColors.dialogInputBorder),
                  focusedBorder: _inputBorder(AppColors.primary),
                ),
              ),

              // ④-5 저장 실패 문구 (실패했을 때만)
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 34),

              // ④-6 버튼: 취소(저장 중 비활성) / 확인(별점 선택 + 저장 중 아님일 때만)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: MovieLogButton(
                        label: '취소',
                        height: 46,
                        borderRadius: 23,
                        fontSize: 15,
                        backgroundColor: AppColors.secondaryButton,
                        foregroundColor: AppColors.primary,
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: MovieLogButton(
                        label: '확인',
                        height: 46,
                        borderRadius: 23,
                        fontSize: 15,
                        isLoading: _isSubmitting,
                        onPressed: _score > 0 && !_isSubmitting
                            ? _onConfirm
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ⑤ 입력창 테두리 (Figma: 2px, 모서리 12) ──
  OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 2),
    );
  }

  // ── ⑥ 확인: 잠금 → 검사 → 저장(onSubmit) → 성공이면 닫기 / 실패면 풀고 문구 ──
  Future<void> _onConfirm() async {
    // ⑥-1 잠금 + 이전 오류 지우기
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    // ⑥-2 코멘트 정리 + 길이 검사
    final trimmed = _commentController.text.trim();
    if (trimmed.length > 500) {
      setState(() {
        _isSubmitting = false;
        _errorText = '코멘트는 500자 이하로 입력해 주세요.';
      });
      return;
    }

    // ⑥-3 저장 실행 (빈 코멘트는 null로)
    try {
      await widget.onSubmit(_score, trimmed.isEmpty ? null : trimmed);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      // ⑥-4 실패: 잠금 해제, 입력은 그대로, 문구 표시
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = error is StateError
            ? error.message
            : '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }
}
