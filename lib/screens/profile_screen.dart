import 'package:flutter/material.dart';
import 'package:joljak/theme/app_colors.dart';
import 'package:provider/provider.dart';

import 'package:joljak/providers/auth_provider.dart';
import 'package:joljak/providers/group_provider.dart';

import 'package:joljak/widgets/common_widgets/whitebox.dart';
import 'package:joljak/widgets/common_widgets/greybox.dart';
import 'package:joljak/widgets/profile_widgets/group_add_btn.dart';
import 'package:joljak/widgets/profile_widgets/group_card.dart';

import '../widgets/bottom_sheet_widgets/trip_record_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    // ✅ 첫 빌드 때 한 번만 그룹 목록 로드 (Provider 내부에서 중복 방지)
    context.read<GroupProvider>().load();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<GroupProvider>().load(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            physics: const AlwaysScrollableScrollPhysics(),
            // 컨텐츠가 짧아도 당겨서 새로고침 허용
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: const Text(
                        '프로필',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 로그아웃: 우상단 고정 (폭 좁을 때 자동 축소)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          // ✅ 색상 지정
                          foregroundColor: AppColors.mainColor,
                          // 텍스트+아이콘 색
                          side: BorderSide(color: Colors.grey, width: 0.1),
                          // 테두리 색
                          // (선택) 눌림 효과
                          overlayColor: AppColors.mainColor,
                          // (선택) 배경색 쓰고 싶으면:
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('로그아웃 되었습니다.')),
                          );
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: AppColors.mainColor,
                        ),
                        label: const Text('로그아웃'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 상단 프로필 카드 ──────────────────────────────────────────────
                Whitebox(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // 버튼을 윗줄에 맞추기
                        children: [
                          // 아바타
                          ClipOval(
                            child: Container(
                              width: 100,
                              height: 100,
                              color: const Color(0xFFF9F9F9),
                              child: const Center(
                                child: Icon(
                                  Icons.person, // 원하는 아이콘
                                  size: 50, // 아이콘 크기
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // 이름/이메일: 아바타와 세로 중앙 정렬
                          Expanded(
                            child: SizedBox(
                              height: 100, // 아바타와 동일 높이
                              child: Align(
                                alignment: Alignment.centerLeft,
                                // 세로 가운데 + 왼쪽 정렬
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      auth.userDisplayName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ?? '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '나의 기록',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 작성한 일기 수
                          Greybox(
                            icon: const Icon(Icons.edit, size: 30),
                            textInt: Text(
                              '${context.watch<TripRecordProvider>().items.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                              ),
                            ),
                            textStr: '작성한 일기',
                          ),

                          // 자주 찾는 그룹 (가장 많이 등장한 group name)
                          Builder(
                            builder: (context) {
                              final items = context
                                  .watch<TripRecordProvider>()
                                  .items;

                              // 최빈 그룹 계산 (group이 non-nullable이면 r.group.name 사용)
                              final groupCounts = <String, int>{};
                              for (final r in items) {
                                final name = r
                                    .group
                                    .name; // nullable이면 r.group?.name ?? '' 로
                                if (name.isNotEmpty) {
                                  groupCounts[name] =
                                      (groupCounts[name] ?? 0) + 1;
                                }
                              }
                              final topGroup = groupCounts.isNotEmpty
                                  ? groupCounts.entries
                                  .reduce(
                                    (a, b) => a.value >= b.value ? a : b,
                              )
                                  .key
                                  : '';

                              // 그룹 색상 찾기 (없으면 회색)
                              final gp = context.watch<GroupProvider>();
                              final color = gp.groups
                                  .firstWhere(
                                    (g) => g.name == topGroup,
                                orElse: () => UiGroup(
                                  id: '',
                                  name: '-',
                                  color: Colors.grey,
                                ),
                              )
                                  .color;

                              return Greybox(
                                icon: const Icon(Icons.group, size: 35),
                                textInt: Text.rich(
                                  TextSpan(
                                    children: [
                                      // 아이콘을 텍스트 '알파벳 베이스라인'에 정렬
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Transform.translate(
                                          offset: const Offset(0, -3),
                                          // -1.0 ~ -2.0 사이로 미세 조정
                                          child: Icon(
                                            Icons.location_on,
                                            size: 25,
                                            color: color,
                                          ),
                                        ),
                                      ),

                                      WidgetSpan(
                                        alignment:
                                        PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: const SizedBox(width: 0.5),
                                      ),
                                      TextSpan(
                                        text: topGroup,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 25,
                                          height: 1.0, // 줄높이로 인한 흔들림 방지
                                        ),
                                      ),
                                    ],
                                  ),
                                  textHeightBehavior: const TextHeightBehavior(
                                    applyHeightToFirstAscent: false,
                                    applyHeightToLastDescent: false,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),

                                textStr: '자주 찾는 그룹',
                              );
                            },
                          ),

                          // AR 사진 수 (photoUrls가 비어있지 않은 기록 개수)
                          Builder(
                            builder: (context) {
                              final items = context
                                  .watch<TripRecordProvider>()
                                  .items;
                              final photoCount = items
                                  .where((r) => r.photoUrls.isNotEmpty)
                                  .length;

                              return Greybox(
                                icon: const Icon(Icons.photo_camera, size: 30),
                                textInt: Text(
                                  '$photoCount',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 40,
                                  ),
                                ),
                                textStr: 'AR 사진',
                              );
                            },
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
                      const Text(
                        '그룹 관리',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Consumer<GroupProvider>(
                        builder: (context, gp, _) {
                          if (gp.isLoading && gp.groups.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                height: 48,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }

                          if (gp.error != null && gp.groups.isEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '불러오기 실패: ${gp.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => gp.load(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('다시 시도'),
                                ),
                              ],
                            );
                          }

                          // ✅ 반응형 Grid
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              // 한 줄에 몇 개 보여줄지 계산 (최소 120px 폭 보장)
                              final crossAxisCount =
                              (constraints.maxWidth / 120).floor().clamp(
                                3,
                                4,
                              );

                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  for (final g in gp.groups)
                                    GroupCard(
                                      groupId: g.id,
                                      name: g.name,
                                      color: g.color,
                                    ),
                                  const GroupAddBtn(),
                                ],
                              );
                            },
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
      ),
    );
  }
}
