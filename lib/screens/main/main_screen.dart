import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../view_models/auth_view_model.dart';

/// 홈·영화·마이 탭이 공유하는 공통 레이아웃.
/// body에는 ShellRoute가 전달한 탭 화면(child)만 바뀌어 표시된다.
///
/// StatefulWidget인 이유(8주차): 탭을 바꿔도 State가 유지되므로
/// initState에서 내 정보(GET me)를 "로그인 세션당 한 번" 불러올 수 있다.
/// 선택된 탭은 여전히 State가 아니라 URL에서 계산한 currentIndex로 받는다.
class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex; // AppRouter.indexFromLocation 결과
  final Widget child; // 현재 탭 화면 (HomeScreen / MovieListScreen / ProfileScreen)

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // loadMember()는 시작하자마자 notifyListeners()를 부르므로
    // build 도중이 아니라 첫 frame이 그려진 뒤에 호출한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 신규 로그인: 여기서 GET me / 앱 재시작: restoreSession이 이미 채워 즉시 return
      context.read<AuthViewModel>().loadMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 바깥 Scaffold: NavigationBar 담당.
    // 각 탭 화면도 자기 Scaffold(AppBar 담당)를 가지므로 Scaffold가 중첩되는데, 정상 패턴이다.
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.currentIndex,
        // 탭 전환은 go: 스택에 쌓지 않고 현재 위치 자체를 바꾼다.
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/movies');
            case 2:
              context.go('/my');
          }
        },
        // destinations의 순서 = index. switch와 indexFromLocation의 번호와 맞아야 한다.
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: '영화',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}
