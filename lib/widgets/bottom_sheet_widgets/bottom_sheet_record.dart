import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import 'trip_record.dart';

class BottomSheetRecord extends StatelessWidget {
  const BottomSheetRecord({
    super.key,
    required this.record,
  });

  final TripRecord record;

  String _formatDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final r = record;
    final dt = r.date;

    // 그룹 색상: Provider 우선 → 모델 hex(없으면 기본)
    final storeGroupColor = context.select<GroupProvider, Color?>((gp) {
      try {
        return gp.groups.firstWhere((g) => g.id == r.group.id).color;
      } catch (_) {
        return null;
      }
    });
    final iconColor = storeGroupColor ?? const Color(0xFFFF5757);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 사진 캐러셀 (있을 때만) ───────────────────────────
          if (r.photoUrls.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: PageView.builder(
                        itemCount: r.photoUrls.length,
                        itemBuilder: (_, i) => Image.network(
                          r.photoUrls[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                    // 간단한 개수 뱃지 (인디케이터 대신)
                    if (r.photoUrls.length > 1)
                      Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${r.photoUrls.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── 타이틀/설명/날짜 + 위치 ───────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title.isEmpty ? "Title" : r.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.content.isEmpty ? "Description" : r.content,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(dt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // 오른쪽 위치
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (r.group.name.trim().isNotEmpty) ...[
                    Icon(Icons.place_outlined, size: 16, color: iconColor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    r.group.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
