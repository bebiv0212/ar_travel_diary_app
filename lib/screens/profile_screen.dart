import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:joljak/providers/auth_provider.dart';
import 'package:joljak/providers/group_provider.dart';

import 'package:joljak/widgets/common_widgets/whitebox.dart';
import 'package:joljak/widgets/common_widgets/greybox.dart';
import 'package:joljak/widgets/profile_widgets/group_add_btn.dart';

import '../widgets/profile_widgets/group_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('프로필', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              // ── 상단 프로필 카드 ──────────────────────────────────────────────
              Whitebox(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // 버튼을 윗줄에 맞추기
                      children: [
                        // 아바타
                        ClipOval(
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey,
                            // child: user?.avatarUrl != null ? Image.network(user!.avatarUrl!, fit: BoxFit.cover) : null,
                          ),
                        ),
                        const SizedBox(width: 20),

                        // 이름/이메일: 아바타와 세로 중앙 정렬
                        Expanded(
                          child: SizedBox(
                            height: 100, // 아바타와 동일 높이
                            child: Align(
                              alignment: Alignment.centerLeft, // 세로 가운데 + 왼쪽 정렬
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.userDisplayName,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 로그아웃: 우상단 고정 (폭 좁을 때 자동 축소)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () async {
                              await context.read<AuthProvider>().logout();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('로그아웃 되었습니다.')),
                              );
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('로그아웃'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text('나의 기록', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Greybox(
                          icon: Icon(Icons.edit, size: 30),
                          textInt: Text('12', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40)),
                          textStr: '친구',
                        ),
                        Greybox(
                          icon: Icon(Icons.group, size: 35),
                          textInt: Text('8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40, height: 1)),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.purple),
                              SizedBox(width: 2),
                              Text('대학교 친구', overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          textStr: '자주 찾는 그룹',
                          textStrStyle: TextStyle(fontSize: 12),
                        ),
                        Greybox(
                          icon: Icon(Icons.photo_camera, size: 30),
                          textInt: Text('12', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40)),
                          textStr: 'AR 사진',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── 그룹 관리 카드 ────────────────────────────────────────────────
              Whitebox(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('그룹 관리', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    Consumer<GroupProvider>(
                      builder: (context, gp, _) {
                        if (gp.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              height: 48,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final g in gp.groups)
                              GroupCard(
                                groupId: g.id,         // 또는 g._id (모델에 맞게)
                                name: g.name,
                                color: g.color,
                                // onEdited: () => gp.fetchGroups(), // 필요시 새로고침 콜백
                              ),
                            const GroupAddBtn(),
                          ],
                        );
                      },
                    ),
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

