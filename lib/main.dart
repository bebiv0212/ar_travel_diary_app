import 'package:flutter/material.dart';
import 'package:joljak/screens/ar_camera_screen.dart';
import 'package:joljak/screens/map_screen.dart';
import 'package:joljak/screens/profile_screen.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AuthRepository.initialize(appKey: '43fc3e9b764885aff8268399009c6d9c');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    MapScreen(),
    ArCameraScreen(),
    ProfileScreen()
  ];

  void _onTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Travel Diary',
        debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTapped,
          selectedItemColor: const Color(0xFFFF8040), // 선택된 아이콘/텍스트 색
          unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera), label: 'AR 카메라'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],),
      )
    );
  }
}
