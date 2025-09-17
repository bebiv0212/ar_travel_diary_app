import 'package:flutter/material.dart';
import 'package:joljak/widgets/common_widgets/greybox.dart';
import 'package:joljak/widgets/common_widgets/whitebox.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              spacing: 15,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 15),
                Text(
                  '프로필',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Whitebox(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            children: [
                              Text(
                                'username',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'example123@email.com',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Text(
                        '나의 기록',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Greybox(
                            icon: Icon(Icons.edit, size: 30),
                            text_int: Text(
                              '12',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                              ),
                            ),
                            text_str: '친구',
                          ),
                          Greybox(
                            icon: Icon(Icons.group, size: 35),
                            text_int: Text(
                              '8',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                                height: 1,
                              ),
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.purple,
                                ),
                                Text('대학교 친구'), // 여기에 그룹을 db에서 받아와야함
                              ],
                            ),
                            text_str: '자주 찾는 그룹',
                            textStrStyle: TextStyle(fontSize: 12),
                          ),
                          Greybox(
                            icon: Icon(Icons.photo_camera, size: 30),
                            text_int: Text(
                              '12',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                              ),
                            ),
                            text_str: 'AR 사진',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Whitebox(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '그룹 관리',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          print("그룹 추가하기 클릭됨!");
                        },
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, size: 100),
                              Text(
                                '그룹 추가하기',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
