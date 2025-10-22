// lib/widgets/bottom_sheet_widgets/data_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/photo_utils.dart';

import 'trip_record.dart';
import 'trip_record_provider.dart';
import 'trip_record_edit_page.dart';
import 'package:joljak/providers/group_provider.dart';

/// hex -> Color (예: "FF5757" / "#FF5757")
Color _hexToColor(String? hex, {Color fallback = const Color(0xFFFF5757)}) {
  if (hex == null || hex.isEmpty) return fallback;
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  try {
    return Color(int.parse('0x$h'));
  } catch (_) {
    return fallback;
  }
}

class DataPage extends StatelessWidget {
  const DataPage({
    super.key,
    required this.record,
    this.embedded = false,                 // 바텀시트에 끼워 넣을 때 true
    this.scrollController,                 // DraggableScrollableSheet 컨트롤러 전달용
    this.showTopBar = true,                // 상단 핸들/닫기/액션 바 노출 여부
    this.onDeleted,                        // 임베디드일 때 삭제 알림 콜백
  });

  final TripRecord record;
  final bool embedded;
  final ScrollController? scrollController;
  final bool showTopBar;
  final VoidCallback? onDeleted;

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 밖 터치로 닫혀도 null 방지
      builder: (_) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 기록을 삭제하면 복구할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // 취소 = false
            child: const Text('취소'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),  // 삭제 = true
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return result == true; // 오직 true일 때만 진행
  }

  // ✅ 편집/삭제 공용 액션
  Widget _buildActions(BuildContext context, TripRecord r) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: '편집',
          onPressed: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<TripRecordProvider>(),
                  child: TripRecordEditPage(record: r),
                ),
              ),
            );
    if (updated is TripRecord) {
    context.read<TripRecordProvider>().upsertLocal(updated);
    }

          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5757)),
          tooltip: '삭제',
          onPressed: () async {
            final ok = await _confirmDelete(context);
            if (ok != true) return; // 취소/백키 모두 종료

            try {
              await context.read<TripRecordProvider>().deleteById(r.id);

              // 임베디드(바텀시트 내부)면 라우트 pop 금지 → 부모 콜백으로 전환
              final isEmbedded = embedded || !showTopBar;
              if (isEmbedded) {
                onDeleted?.call();
              } else {
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context, 'deleted'); // 페이지 모드만 닫기
                }
              }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('삭제 실패: $e')),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 최신 데이터 구독(편집/삭제 반영), 없으면 초기값 사용
    final r = context.select<TripRecordProvider, TripRecord?>((p) {
      try {
        return p.items.firstWhere((e) => e.id == record.id);
      } catch (_) {
        return null;
      }
    }) ?? record;

    final photos = r.photoUrls;
    final showGroupChip = r.group.name.trim().isNotEmpty;

    // 그룹 색상: Provider 우선 → 모델 hex → 폴백
    final storeGroupColor = context.select<GroupProvider, Color?>((gp) {
      try {
        return gp.groups.firstWhere((g) => g.id == r.group.id).color;
      } catch (_) {
        return null;
      }
    });
    final Color groupColor = storeGroupColor ?? _hexToColor(r.group.color);

    // ✨ “내용”만 그리는 위젯 (임베디드/페이지 공용)
    final Widget body = CustomScrollView(
      controller: scrollController ?? PrimaryScrollController.maybeOf(context),
      slivers: [
        // 상단 핸들 + 닫기 + 액션(편집/삭제) — 페이지 모드에서만
        if (showTopBar)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        tooltip: '닫기',
                      ),
                      const Spacer(),
                      _buildActions(context, r), // 공용 액션
                    ],
                  ),
                ],
              ),
            ),
          ),

        // 제목 / 날짜 / 그룹칩 (+ 임베드 모드일 땐 우측에 액션 노출)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.title.isEmpty ? 'Title' : r.title,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!showTopBar) _buildActions(context, r), // 바텀시트 임베드 시 여기서 보여줌
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(_ymd(r.date), style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    const Spacer(),
                    if (showGroupChip)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place_outlined, size: 16, color: groupColor),
                            const SizedBox(width: 4),
                            Text(
                              r.group.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),

        // 사진 가로 스크롤 (있을 때만)
        if (photos.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 10),
              child: SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final url = photos[i].trim();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: buildPhotoThumb(url),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // 본문
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: Text(
              r.content.isEmpty ? '일기 내용' : r.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
      ],
    );

    // 바텀시트 임베드면 Scaffold 없이 “내용만” 반환
    if (embedded) {
      return body;
    }

    // 기존처럼 페이지로 띄우는 경우
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: body),
    );
  }
}
