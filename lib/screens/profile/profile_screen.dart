import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/movielog_app_bar.dart';
import 'widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MovieLogAppBar(title: '내 프로필'),
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
            SizedBox(height: 28),
            FavoriteGenres(),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              fit: BoxFit.cover, // 비율을 유지하며 영역을 꽉 채움
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('무비러버', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
            textAlign: TextAlign.center,
          ),
        ),
        // Margin: 버튼 '바깥'을 띄운다 (소개 문장과의 간격)
        Container(
          margin: const EdgeInsets.only(top: 16),
          child: TextButton(
            onPressed: () {}, // 1주차에는 동작을 연결하지 않습니다.
            style: TextButton.styleFrom(
              side: BorderSide(color: colors.primary),
              // Padding: 버튼 '안쪽'을 띄운다 (테두리와 글자 사이)
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
