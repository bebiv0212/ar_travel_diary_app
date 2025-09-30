// lib/widgets/bottom_sheet_widgets/data_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'trip_record.dart';
import 'trip_record_provider.dart';
import 'trip_record_edit_page.dart';
// (Optional) 그룹 이름 매핑을 쓰고 싶으면 아래 임포트와 groupName 부분 주석 해제
// import 'package:joljak/providers/group_provider.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key, required this.record});
  final TripRecord record;

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  late TripRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    // Optional: GroupProvider에서 이름 매핑 (없으면 주석 유지)
    // final groupName = context.select<GroupProvider, String?>(
    //   (gp) => gp.nameOf(_record.groupId),
    // );
    final showGroupChip = (_record.group.name ?? '').isNotEmpty;
    final groupText = /* groupName ?? */ 'Group';

    final photos = _record.photoUrls;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 상단 핸들 + 액션바(뒤로/편집)
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
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          tooltip: '편집',
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: context.read<TripRecordProvider>(),
                                  child: TripRecordEditPage(record: _record),
                                ),
                              ),
                            );
                            if (updated is TripRecord && mounted) {
                              setState(() => _record = updated); // 상세 즉시 갱신
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
                    Text(
                      _record.title.isEmpty ? 'Title' : _record.title,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _ymd(_record.date),
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
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
                              children: [
                                const Icon(Icons.lightbulb_outline, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  groupText,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                      itemBuilder: (context, index) {
                        final url = photos[index].trim();
                        final hasUrl = url.isNotEmpty;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: hasUrl
                                ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
                            )
                                : const _PhotoPlaceholder(),
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
                  _record.content.isEmpty ? '일기 내용' : _record.content,
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
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          isFirst ? '사진' : '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
