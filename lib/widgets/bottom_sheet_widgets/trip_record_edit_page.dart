// lib/widgets/bottom_sheet_widgets/trip_record_edit_page.dart

import 'package:flutter/material.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/photo_utils.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'trip_record.dart';
import 'trip_record_provider.dart';
import 'package:joljak/providers/group_provider.dart'; // UiGroup / GroupProvider

class TripRecordEditPage extends StatefulWidget {
  const TripRecordEditPage({super.key, required this.record});
  final TripRecord record;

  @override
  State<TripRecordEditPage> createState() => _TripRecordEditPageState();
}

class _TripRecordEditPageState extends State<TripRecordEditPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late DateTime _date;
  late List<String> _photoPathsOrUrls; // 로컬 파일 path 또는 http(s) URL
  bool _saving = false;

  // ⚠️ late 에러 방지용 기본값 후 initState에서 주입
  GroupInfo _group = GroupInfo.empty;

  final ImagePicker _picker = ImagePicker(); // 갤러리 전용

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.record.title);
    _contentCtrl = TextEditingController(text: widget.record.content);
    _date = widget.record.date;
    _photoPathsOrUrls = List<String>.from(widget.record.photoUrls);
    _group = widget.record.group; // 초기 그룹 주입

    // 페이지 진입 시 그룹 목록이 없으면 한 번 로드
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gp = context.read<GroupProvider>();
      if (gp.groups.isEmpty && !gp.isLoading) {
        await gp.load();
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool _isHttpUrl(String s) {
    final u = s.toLowerCase();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  /// 갤러리에서 여러 장 선택 (Android는 추가 설정 없이 동작)
  Future<void> _pickPhotosFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;
      setState(() {
        _photoPathsOrUrls.addAll(images.map((x) => x.path)); // 로컬 파일 경로
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }

  /// ✅ “가운데 뜨는 창”으로 그룹 선택 (지정 안 함 포함 / 버튼 선택)
  Future<void> _openGroupDialog() async {
    final gp = context.read<GroupProvider>();

    // 열기 전 로드 보장
    List<UiGroup> groups = gp.groups;
    if (groups.isEmpty && !gp.isLoading) {
      await gp.load();
      groups = gp.groups; // 로드 후 스냅샷 고정
    }

    const kNoneId = '__NONE__'; // ‘지정 안 함’ 식별자

    final pickedId = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('그룹 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 맨 위 ‘지정 안 함’ 버튼
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx, kNoneId),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('지정 안 함'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('등록된 그룹이 없습니다.'),
                    )
                  else
                    ...groups.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx, g.id),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            g.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, null),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );

    if (!mounted || pickedId == null) return;

    if (pickedId == kNoneId) {
      // ✅ ‘지정 안 함’
      setState(() => _group = GroupInfo.empty);
      return;
    }

    final sel = groups.firstWhere((x) => x.id == pickedId, orElse: () => groups.first);
    setState(() {
      _group = GroupInfo(id: sel.id, name: sel.name, color: null);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해 주세요.')),
      );
      return;
    }

    // 서버는 URL 배열을 받으므로, 로컬 경로는 제외하고 전송 (업로드 API 전 임시)
    final urlsOnly = _photoPathsOrUrls.where(_isHttpUrl).toList();
    final hasLocal = _photoPathsOrUrls.any((p) => !_isHttpUrl(p));

    setState(() => _saving = true);
    final p = context.read<TripRecordProvider>();
    try {
      // 그룹 변경 여부 판단
      final changed = _group.id != widget.record.group.id;

      // ⚠️ 서버 규약에 맞추세요:
      //  - 대부분은 ''(빈 문자열)을 보내면 groupId를 null로 업데이트(해제)합니다.
      //  - 서버가 null로 해제한다면 아래를 null로 바꾸세요.
      final String? sendGroupId = changed
          ? (_group.id.isEmpty ? '' : _group.id)
          : null;

      final updated = await p.updateRecord(
        id: widget.record.id,
        title: title,
        content: _contentCtrl.text.trim(),
        date: _date,
        photoUrls: urlsOnly,
        groupId: sendGroupId, // ✅ 지정/해제 모두 한 번에 처리
      );
      await p.refresh();

      if (mounted) {
        if (hasLocal) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로컬에서 고른 사진은 업로드 연결 전이라 저장되지 않았어요.')),
          );
        }
        Navigator.pop(context, updated); // DataPage로 결과 객체 반환
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider에서 최신 이름(있으면) → 없으면 로컬 _group.name
    final storeGroupName = context.select<GroupProvider, String?>((gp) {
      try {
        final g = gp.groups.firstWhere((x) => x.id == _group.id);
        return g.name;
      } catch (_) {
        return null;
      }
    });
    // 이미 있던 이름 로직 옆에 추가
   final storeGroupColor = context.select<GroupProvider, Color?>((gp) {
      try {
        return gp.groups.firstWhere((x) => x.id == _group.id).color; // UiGroup.color
      } catch (_) {
        return null;
      }
    });

// // 최종 보여줄 색 (Provider 우선 → 모델의 hex → 기본색)
//     final Color groupColor = _group.color


    final displayedGroupName = ((storeGroupName ?? _group.name).trim());
    final hasGroup = displayedGroupName.isNotEmpty;
    final chipLabel = hasGroup ? displayedGroupName : '지정 안 함';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 상단 핸들 + 제목/날짜/그룹
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Title',
                            ),
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              InkWell(
                                onTap: _pickDate,
                                child: Row(
                                  children: [
                                    const Icon(Icons.event, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      _ymd(_date),
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),

                              // ✅ 그룹 칩 (탭 → 가운데 다이얼로그)
                              InkWell(
                                onTap: _openGroupDialog,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (hasGroup) ...[
                                        Icon(Icons.place_outlined, size: 16 ,color:  storeGroupColor,),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        chipLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: hasGroup ? null : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 사진 가로 스크롤: [+ 추가] + 썸네일들(로컬/URL 모두)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 18, right: 10),
                child: SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 1 + _photoPathsOrUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _AddPhotoTile(onTap: _pickPhotosFromGallery);
                      }
                      final path = _photoPathsOrUrls[index - 1].trim();
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: buildPhotoThumb(path),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: InkWell(
                              onTap: () => setState(
                                      () => _photoPathsOrUrls.removeAt(index - 1)),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // 본문 입력
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _contentCtrl,
                    maxLines: null,
                    minLines: 5,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '일기 내용을 자유히 적어줘...',
                    ),
                  ),
                ),
              ),
            ),

            // CANCEL / SAVE
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8040),
                          foregroundColor: Colors.white,
                        ),
                        child: _saving
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'SAVE',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: const Center(
          child: Icon(Icons.add_photo_alternate_outlined, size: 28),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Text('사진', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
