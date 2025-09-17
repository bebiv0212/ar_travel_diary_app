import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';

import 'screens/map_screen.dart';
import 'screens/ar_camera_screen.dart';
import 'screens/profile_screen.dart';
// import 'screens/login_screen.dart'; // 🔕 임시 비활성화: 로그인 게이트 끈 상태라 필요 없음

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AuthRepository.initialize(appKey: '43fc3e9b764885aff8268399009c6d9c');
  runApp(const MyApp());
}

/// 🔧 토글 스위치: 나중에 로그인 게이트 켜고 싶으면 true로만 바꾸세요.
const bool kEnableAuthGate = false; // ← 임시로 로그인 건너뜀

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 세션은 여전히 로드하지만, 초기 라우팅에는 사용하지 않습니다.
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSession()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'AR Travel Diary',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        ),
        // ✅ 임시: 홈을 직접 보여줌 (로그인 화면 X)
        home: kEnableAuthGate ? const _AuthGate() : const _HomeScaffold(),
      ),
    );
  }
}

/// (보관용) 원래의 로그인 게이트 — 지금은 kEnableAuthGate=false 라서 사용 안 함
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading && !auth.isLoggedIn && auth.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // 로그인 안되어 있으면 로그인 화면으로 보내고 싶다면 여기서 분기
    // return auth.isLoggedIn ? const _HomeScaffold() : const LoginScreen();
    return const _HomeScaffold(); // 🔕 임시: 로그인 상태 무시하고 바로 홈
  }
}

/// 하단 탭 + 페이지 컨테이너
class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold();

  static final List<Widget> _pages = [
    const MapScreen(),
    const ArCameraScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    return Scaffold(
      body: _pages[nav.index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: nav.index,
        onTap: (i) => context.read<NavigationProvider>().setIndex(i),
        selectedItemColor: const Color(0xFFFF8040),
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera), label: 'AR 카메라'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
    );
  }
}
