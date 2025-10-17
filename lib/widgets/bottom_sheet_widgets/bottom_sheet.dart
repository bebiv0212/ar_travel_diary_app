import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_page.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/bottom_sheet_record.dart';
import 'trip_record.dart';
import 'trip_record_provider.dart';

// ➊ 전역 RouteObserver (앱의 MaterialApp에 등록 필요)
final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();

class MyBottomSheet extends StatefulWidget {
  const MyBottomSheet({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<MyBottomSheet> createState() => _MyBottomSheetState();
}

class _MyBottomSheetState extends State<MyBottomSheet> with RouteAware {
  Future<void> _pullToRefresh() async {
    await context.read<TripRecordProvider>().refresh();
  }

  bool _handleScroll(ScrollNotification n) {
    final p = context.read<TripRecordProvider>();
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
        !p.loading &&
        p.hasMore) {
      p.loadMore();
    }
    return false; // 다른 리스너도 받도록
  }

  // ➋ 이 화면(바텀시트)이 다시 보일 때마다 자동 새로고침
  @override
  void didPopNext() {
    // 생성/상세 페이지에서 뒤로 왔을 때 호출
    context.read<TripRecordProvider>().refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
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
                if (mounted && !p.initialLoaded && !p.loading) {
                  p.refresh();
                }
              });
            }

            final items = p.items;

            return RefreshIndicator(
              onRefresh: _pullToRefresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScroll,
                child: CustomScrollView(
                  controller: widget.scrollController,
                  slivers: [
                    // 드래그 핸들
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 12),
                        child: Center(
                          child: _DragHandle(),
                        ),
                      ),
                    ),

                    // 🔒 고정 헤더: "나의 기록"
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedHeaderDelegate(
                        height: 60,
                        child: Container(
                          color: Colors.white,
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
                              onTap: () async {
                                // 상세 진입 후 되돌아올 때 didPopNext로 자동 새로고침
                                await Navigator.push(
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// 고정 헤더용 Delegate
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

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
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
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
        Icon(Icons.travel_explore, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('기록이 없습니다. 첫 여행 기록을 추가해 보세요.'),
        const SizedBox(height: 24),
      ],
    );
  }
}
