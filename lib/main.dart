import 'package:flutter/material.dart';
import 'package:joljak/providers/group_provider.dart';
import 'package:joljak/screens/ar_camera_page.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/trip_record_provider.dart';
import 'package:provider/provider.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart'; // ✅ 로그인 화면 다시 활성화

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AuthRepository.initialize(appKey: '43fc3e9b764885aff8268399009c6d9c');
  runApp(const MyApp());
}

/// 🔧 토글 스위치: 로그인 게이트 켜기
const bool kEnableAuthGate = true; // ✅ 로그인 테스트 위해 활성화

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 세션은 여전히 로드
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSession()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => TripRecordProvider()),
      ],
      child: MaterialApp(
        title: 'AR Travel Diary',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF9F9F9),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white, // 메인 톤 기준 색
          ),
        ),
        home: kEnableAuthGate ? const _AuthGate() : const _HomeScaffold(),
      ),
    );
  }
}

/// 로그인 게이트
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1) 세션 로딩 중
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2) 로그인됨 → 홈
    if (auth.isLoggedIn && auth.user != null) {
      return const _HomeScaffold();
    }

    // 3) 로그인 안됨 → 로그인 화면
    return const LoginScreen();
  }
}

/// 하단 탭 + 페이지 컨테이너
class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold();

  static final List<Widget> _pages = [
    const MapScreen(),
    const ArCameraPage(),
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
