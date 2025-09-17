import 'package:flutter/material.dart';
import 'package:joljak/widgets/common_widgets/greybox.dart';
import 'package:joljak/widgets/common_widgets/whitebox.dart';
import 'package:joljak/widgets/profile_widgets/group_add_btn.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 상단 타이틀
              const Text(
                '프로필',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // 상단 카드
              Whitebox(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 프로필 영역
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 아바타
                        ClipOval(
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey,
                            // child: Image.network(avatarUrl, fit: BoxFit.cover), // 나중에 이미지 연결 시
                          ),
                        ),
                        const SizedBox(width: 20),
                        // 이름/이메일 (좌측 정렬)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'username',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'example123@email.com',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '나의 기록',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // 기록 카드 3개
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Greybox(
                          icon: const Icon(Icons.edit, size: 30),
                          textInt: const Text(
                            '12',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                          ),
                          textStr: '친구',
                        ),
                        Greybox(
                          icon: const Icon(Icons.group, size: 35),
                          textInt: const Text(
                            '8',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40, height: 1),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.location_on, size: 12, color: Colors.purple),
                              SizedBox(width: 2),
                              Text('대학교 친구', overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          textStr: '자주 찾는 그룹',
                          textStrStyle: const TextStyle(fontSize: 12),
                        ),
                        Greybox(
                          icon: const Icon(Icons.photo_camera, size: 30),
                          textInt: const Text(
                            '12',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                          ),
                          textStr: 'AR 사진',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 그룹 관리
              Whitebox(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '그룹 관리',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // 버튼은 Material + InkWell 권장 (리플/접근성)
                    GroupAddBtn(),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
