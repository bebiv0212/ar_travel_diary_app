import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:joljak/providers/auth_provider.dart';
import 'package:joljak/providers/group_provider.dart';

import 'package:joljak/widgets/common_widgets/whitebox.dart';
import 'package:joljak/widgets/common_widgets/greybox.dart';
import 'package:joljak/widgets/profile_widgets/group_add_btn.dart';

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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey,
                            // child: user?.avatarUrl != null ? Image.network(user!.avatarUrl!, fit: BoxFit.cover) : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.userDisplayName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(fontSize: 15, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
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
                            for (final g in gp.groups) _GroupCard(name: g.name, color: g.color),
                            const GroupAddBtn(), // 항상 마지막에 “+” 타일
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

/// 그룹 카드 (Add 버튼과 동일한 크기/모서리)
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.name, required this.color});
  final String name;
  final Color color;

  static const double tileSize = GroupAddBtn.tileSize;
  static const BorderRadius kRadius = GroupAddBtn.kRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: tileSize,
          height: tileSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: kRadius,
            border: Border.all(color: Colors.black12.withOpacity(0.08)),
          ),
          child: Icon(Icons.place_rounded, color: color, size: 30),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: tileSize + 4,
          child: Text(
            name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
