// lib/widgets/bottom_sheet_widgets/my_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_page.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/bottom_sheet_record.dart';
import 'trip_record.dart';
import 'trip_record_provider.dart';

class MyBottomSheet extends StatefulWidget {
  const MyBottomSheet({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<MyBottomSheet> createState() => _MyBottomSheetState();
}

class _MyBottomSheetState extends State<MyBottomSheet> {
  TripRecord? _selected; // ← null이면 목록 모드, 있으면 상세 모드

  Future<void> _pullToRefresh(BuildContext context) async {
    await context.read<TripRecordProvider>().refresh();
  }

  bool _handleScroll(BuildContext context, ScrollNotification n) {
    if (_selected != null) return false; // 상세 모드에선 무한스크롤 X
    final p = context.read<TripRecordProvider>();
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
        !p.loading &&
        p.hasMore) {
      p.loadMore();
    }
    return false; // 다른 리스너들도 알림 받도록
  }

  // 안드로이드 백버튼/제스처: 상세 모드면 목록으로만 돌아가고 시트는 닫지 않음
  Future<bool> _onWillPop() async {
    if (_selected != null) {
      setState(() => _selected = null);
      return false; // pop 방지
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Material(
        elevation: 12,
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Consumer<TripRecordProvider>(
            builder: (context, p, _) {
              // 최초 1회만 로드 (목록 모드에서만)
              if (_selected == null && !p.initialLoaded && !p.loading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!p.initialLoaded && !p.loading) {
                    p.refresh();
                  }
                });
              }

              // 상세 모드: 선택된 레코드의 DataPage 내용만 렌더링
              if (_selected != null) {
                final r = _selected!;
                return Column(
                  children: [
                    // 고정 헤더: 핸들 + 뒤로/닫기
                    _DetailHeader(
                      onBack: () => setState(() => _selected = null),
                      title: r.title.isEmpty ? '상세보기' : r.title,
                    ),
                    // 내용: DataPage를 바텀시트에 임베드
                    Expanded(
                      child: PrimaryScrollController(
                        controller: widget.scrollController,
                        child: DataPage(
                        record: r,
                        embedded: true,
              showTopBar: false,
              scrollController: widget.scrollController,
              onDeleted: () async {
              setState(() => _selected = null);           // 목록으로 전환
              await context.read<TripRecordProvider>().refresh();
              if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('삭제되었습니다.')),
              );

            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }

              // 목록 모드
              final items = p.items;

              return RefreshIndicator(
                onRefresh: () => _pullToRefresh(context),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) => _handleScroll(context, n),
                  child: CustomScrollView(
                    controller: widget.scrollController,
                    slivers: [
                      // 고정 헤더(핸들 + 타이틀)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedHeaderDelegate(
                          minHeight: 86,
                          maxHeight: 86,
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 핸들
                                Padding(
                                  padding: const EdgeInsets.only(top: 10, bottom: 12),
                                  child: Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                                // 타이틀
                                Container(
                                  height: 60,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.centerLeft,
                                  child: const Text(
                                    '나의 기록',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (!p.initialLoaded && p.loading)
                        const SliverToBoxAdapter(child: _InlineLoading()),

                      if (p.initialLoaded && items.isEmpty && !p.loading)
                        const SliverToBoxAdapter(child: _EmptyState()),

                      if (items.isNotEmpty)
                        SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final TripRecord record = items[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: InkWell(
                                onTap: () {
                                  // ✅ 여기! 새 페이지/새 시트로 안 가고,
                                  // 같은 바텀시트 안에서 상세로 전환
                                  setState(() => _selected = record);
                                },
                                child: BottomSheetRecord(record: record),
                              ),
                            );
                          },
                        ),

                      if (p.loading && items.isNotEmpty)
                        const SliverToBoxAdapter(child: _BottomLoading()),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 상세 모드용 상단 헤더 (핸들 + 뒤로 버튼)
class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack, required this.title});
  final VoidCallback onBack;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        child: Column(
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 뒤로 + 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 고정 헤더용 Delegate (오버랩 시 바텀 보더 표시)
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: overlapsContent ? Colors.black12 : Colors.transparent,
            width: 0.5,
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 28),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 28),
      ],
    );
  }
}

class _BottomLoading extends StatelessWidget {
  const _BottomLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(Icons.travel_explore, size: 56, color: Colors.grey[500]),
        const SizedBox(height: 12),
        const Text('기록이 없습니다. 첫 여행 기록을 추가해 보세요.'),
        const SizedBox(height: 24),
      ],
    );
  }
}
