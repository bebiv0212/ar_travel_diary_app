import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_page.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/bottom_sheet_record.dart';
import 'trip_record.dart';
import 'trip_record_provider.dart';

class MyBottomSheet extends StatelessWidget {
  const MyBottomSheet({super.key, required this.scrollController});
  final ScrollController scrollController;

  Future<void> _pullToRefresh(BuildContext context) async {
    await context.read<TripRecordProvider>().refresh();
  }

  bool _handleScroll(BuildContext context, ScrollNotification n) {
    final p = context.read<TripRecordProvider>();
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
        !p.loading &&
        p.hasMore) {
      p.loadMore();
    }
    return false; // 다른 리스너들도 알림 받도록
  }

  @override
  Widget build(BuildContext context) {
    return Material(
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
            // 최초 1회만 로드
            if (!p.initialLoaded && !p.loading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!p.initialLoaded && !p.loading) {
                  p.refresh();
                }
              });
            }

            final items = p.items;

            return RefreshIndicator(
              onRefresh: () => _pullToRefresh(context),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) => _handleScroll(context, n),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // ✅ 핸들 + "나의 기록"을 하나의 고정 헤더로
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedHeaderDelegate(
                        minHeight: 86, // 핸들(26) + 타이틀(60) 높이 합
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

                    // 상태별 블록
                    if (!p.initialLoaded && p.loading)
                      const SliverToBoxAdapter(child: _InlineLoading()),

                    if (p.initialLoaded && items.isEmpty && !p.loading)
                      const SliverToBoxAdapter(child: _EmptyState()),

                    // 아이템 목록
                    if (items.isNotEmpty)
                      SliverList.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final TripRecord record = items[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DataPage(record: record),
                                  ),
                                );
                              },
                              child: BottomSheetRecord(record: record),
                            ),
                          );
                        },
                      ),

                    // 하단 로딩 (무한 스크롤)
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
