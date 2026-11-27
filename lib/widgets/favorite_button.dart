import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../view_models/favorite_detail_view_model.dart';

// ── ① 제목 오른쪽의 북마크 버튼 ──
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  // ── ② 탭 → 서버 결과를 기다린 뒤 Snackbar ──
  Future<void> _toggle(BuildContext context, FavoriteDetailViewModel vm) async {
    await vm.toggle();
    if (!context.mounted) return;
    final message =
        vm.errorMessage ?? (vm.isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.');
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar(); // [기존 화면 규칙] 연속 탭 시 쌓이지 않게
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // ── ③ Consumer: ViewModel이 알릴 때 이 부분만 다시 그림 ──
    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) {
        final busy = vm.isLoading || vm.isSaving;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Figma 3594-41: 62×72 박스, 배경 #FEFCF9, 테두리 1px #D9D3E1
            Material(
              color: AppColors.cardFill,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: InkWell(
                // ── ⑤ 요청 중이거나 여부를 모르면 비활성 ──
                onTap: !busy && vm.hasLoadedStatus
                    ? () => _toggle(context, vm)
                    : null,
                child: SizedBox(
                  width: 62,
                  height: 72,
                  child: Center(
                    // ── ④ 요청 중이면 북마크 자리에 spinner ──
                    child: busy
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primary,
                            ),
                          )
                        : Icon(
                            vm.isFavorite
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 32,
                            color: primary,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 11 Bold primary
            Text(
              '즐겨찾기',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            // ── ⑥ 첫 조회 실패 시에만 새로고침 버튼 ──
            if (!vm.hasLoadedStatus && !vm.isLoading)
              SizedBox(
                width: 62,
                child: IconButton(
                  tooltip: '여부 다시 확인',
                  color: primary,
                  onPressed: vm.load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
          ],
        );
      },
    );
  }
}
