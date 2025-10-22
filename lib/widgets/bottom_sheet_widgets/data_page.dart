// lib/widgets/bottom_sheet_widgets/data_page.dart
import 'package:flutter/material.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/photo_utils.dart';
import 'package:provider/provider.dart';

import 'trip_record.dart';
import 'trip_record_provider.dart';
import 'trip_record_edit_page.dart';
import 'package:joljak/providers/group_provider.dart';

/// hex 문자열을 Color로 (예: "FF5757" / "#FF5757")
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
  const DataPage({super.key, required this.record});
  final TripRecord record; // 최초 전달 받은 값(아이디 사용)

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 기록을 삭제하면 복구할 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.redAccent),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // id로 해당 레코드만 구독 (업데이트/삭제 시 자동 리빌드)
    final r = context.select<TripRecordProvider, TripRecord?>((p) {
      try {
        return p.items.firstWhere((e) => e.id == record.id);
      } catch (_) {
        // 목록에 없으면 (삭제되었거나 필터 변경) 전달받은 초기값을 임시로 사용
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 상단 핸들 + 액션바(뒤로/편집/삭제)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44, height: 4, margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        // 편집
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
                            // 다른 화면과 필터 일관성을 위해 한 번 새로고침
                            if (updated is TripRecord) {
                              await context.read<TripRecordProvider>().refresh();
                            }
                          },
                        ),
                        // 삭제
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5757)),
                          tooltip: '삭제',
                          onPressed: () async {
                            final ok = await _confirmDelete(context);
                            if (!ok) return;
                            try {
                              await context.read<TripRecordProvider>().deleteById(r.id);
                              if (context.mounted) Navigator.pop(context, 'deleted');
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 제목 / 날짜 / 그룹
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title.isEmpty ? 'Title' : r.title,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
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
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({this.isFirst = false});
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Text(isFirst ? '사진' : '', style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
