import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 홈·영화·마이 탭이 공유하는 공통 레이아웃.
/// body에는 ShellRoute가 전달한 탭 화면(child)만 바뀌어 표시된다.
///
/// StatelessWidget인 이유: 선택된 탭을 스스로 기억하지 않고
/// 라우터가 URL에서 계산한 currentIndex를 받기만 하기 때문이다.
class MainScreen extends StatelessWidget {
  const MainScreen({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex; // AppRouter.indexFromLocation 결과
  final Widget child; // 현재 탭 화면 (HomeScreen / MovieListScreen / ProfileScreen)

  @override
  Widget build(BuildContext context) {
    // 바깥 Scaffold: NavigationBar 담당.
    // 각 탭 화면도 자기 Scaffold(AppBar 담당)를 가지므로 Scaffold가 중첩되는데, 정상 패턴이다.
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        // 탭 전환은 go: 스택에 쌓지 않고 현재 위치 자체를 바꾼다.
        // push를 쓰면 탭을 누를 때마다 스택이 쌓여 뒤로가기가 탭 이력을 거슬러 올라간다.
        // setState 없이 URL만 바꾸면 라우터가 MainScreen을 새 currentIndex로 다시 만든다.
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/movies');
              break;
            case 2:
              context.go('/my');
              break;
          }
        },
        // destinations의 순서 = index. switch와 indexFromLocation의 번호와 맞아야 한다.
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), // 선택 안 됨
            selectedIcon: Icon(Icons.home), // 선택됨
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
