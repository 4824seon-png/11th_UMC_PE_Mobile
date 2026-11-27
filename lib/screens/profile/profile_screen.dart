import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/storage/token_storage.dart';
import '../../view_models/auth_view_model.dart';
import '../../widgets/movielog_app_bar.dart';
import 'widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MovieLogAppBar(
        title: '내 프로필',
        actions: [
          // kDebugMode는 const → release 빌드에서는 이 버튼이 아예 빠진다.
          if (kDebugMode) _DebugInvalidateTokenButton(),
          _LogoutButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(),
            SizedBox(height: 24),
            ProfileStats(),
            SizedBox(height: 26),
            MyRatingsEntry(),
            SizedBox(height: 8), // Figma: 평점 행 아래 8
            MyFavoritesEntry(),
            SizedBox(height: 28),
            FavoriteGenres(),
          ],
        ),
      ),
    );
  }
}

/// 앱바 로그아웃. 상태만 signedOut으로 바꾸고 이동은 Router가 한다.
/// 직접 로그아웃은 expired=false → 만료 Snackbar가 뜨지 않는다.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final cleaning = context.select<AuthViewModel, bool>(
      (auth) => auth.storageCleanupInProgress,
    );
    return TextButton(
      onPressed: cleaning ? null : () => context.read<AuthViewModel>().logout(),
      child: const Text('로그아웃', style: TextStyle(fontSize: 13)),
    );
  }
}

/// [디버그 전용] 저장된 토큰을 서버가 거절할 값으로 바꿔 401(AUTH401_3)을 재현한다.
/// 이후 보호 요청(평점·닉네임 저장)이나 앱 재시작에서 만료 흐름을 촬영할 수 있다.
class _DebugInvalidateTokenButton extends StatelessWidget {
  const _DebugInvalidateTokenButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '토큰 무효화 (디버그)',
      icon: const Icon(Icons.bug_report_outlined),
      onPressed: () async {
        // await 전에 필요한 것을 꺼내 둔다 (await 뒤 context 사용 방지)
        final storage = context.read<TokenStorage>();
        final messenger = ScaffoldMessenger.of(context);
        await storage.saveAccessToken('invalid-token-for-test');
        messenger.showSnackBar(
          const SnackBar(content: Text('[디버그] 토큰을 무효화했어요. 보호 요청을 보내 보세요.')),
        );
      },
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // member의 닉네임·이메일만 구독 (record는 값 비교 → 둘 중 하나가 바뀔 때만 rebuild)
    final (nickname, email) = context.select<AuthViewModel, (String?, String?)>(
      (auth) => (auth.member?.nickname, auth.member?.email),
    );
    final hasMember = nickname != null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.primary, width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // GET me 완료 전에는 자리만 유지 (로딩·재시도 UI는 Challenge)
        Text(nickname ?? '…', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          email ?? '',
          style: const TextStyle(fontSize: 13, color: AppColors.commentText),
        ),
        Container(
          margin: const EdgeInsets.only(top: 32),
          child: TextButton(
            // 내 정보가 있어야 수정 화면을 채울 수 있다 → 그 전엔 비활성
            onPressed: hasMember
                ? () => context.push('/my/profile/edit')
                : null,
            style: TextButton.styleFrom(
              side: BorderSide(color: colors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('프로필 수정'),
          ),
        ),
      ],
    );
  }
}

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      // 주축(가로): 카드가 Expanded로 폭을 균등 분배 / 교차축(세로): 위쪽 기준
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StatItem(label: '본 영화', value: '342'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: StatItem(label: '평점', value: '4.2'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: StatItem(label: '즐겨찾기', value: '58'),
        ),
      ],
    );
  }
}

class MyRatingsEntry extends StatelessWidget {
  const MyRatingsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.entryBorder, width: 1.5),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () => context.push('/my/ratings'),
        child: const SizedBox(
          height: 64,
          child: Padding(
            padding: EdgeInsets.only(left: 19, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '내가 등록한 평점',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.labelText,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 28, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ① 내 즐겨찾기 진입 행: 내 정보가 준비된 뒤에만 활성 ──
class MyFavoritesEntry extends StatelessWidget {
  const MyFavoritesEntry({super.key});

  @override
  Widget build(BuildContext context) {
    // ── ② member 존재 여부만 구독 ──
    final hasMember = context.select<AuthViewModel, bool>(
      (auth) => auth.member != null,
    );

    // Figma 3594-132: 358×54, 배경 #FEFCF9, 테두리 1px #D9D3E1 (평점 행과 다름)
    return Material(
      color: AppColors.cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: hasMember ? () => context.push('/my/favorites') : null,
        child: const SizedBox(
          height: 54,
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '내 즐겨찾기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.labelText,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 24, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start, // 주축: 왼쪽부터
          crossAxisAlignment: CrossAxisAlignment.center, // 교차축: 아이콘·글자 세로 중앙
          children: [
            SvgPicture.asset(
              'assets/icons/movie.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text('선호하는 장르', style: textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final g in _genres) Chip(label: Text(g))],
        ),
      ],
    );
  }
}
