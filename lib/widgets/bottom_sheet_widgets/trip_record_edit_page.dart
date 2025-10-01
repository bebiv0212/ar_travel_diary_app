// lib/widgets/bottom_sheet_widgets/trip_record_edit_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'trip_record.dart';
import 'trip_record_provider.dart';

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

  final ImagePicker _picker = ImagePicker(); // ✅ 갤러리 전용

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.record.title);
    _contentCtrl = TextEditingController(text: widget.record.content);
    _date = widget.record.date;
    _photoPathsOrUrls = List<String>.from(widget.record.photoUrls);
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

  /// ✅ 갤러리에서 여러 장 선택 (Android는 추가 설정 없이 동작)
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

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해 주세요.')),
      );
      return;
    }

    // 서버는 URL 배열을 받으므로, 로컬 경로는 제외하고 전송 (업로드 API 붙기 전 임시)
    final urlsOnly = _photoPathsOrUrls.where(_isHttpUrl).toList();
    final hasLocal = _photoPathsOrUrls.any((p) => !_isHttpUrl(p));

    setState(() => _saving = true);
    final p = context.read<TripRecordProvider>();
    try {
      final updated = await p.updateRecord(
        id: widget.record.id,
        title: title,
        content: _contentCtrl.text.trim(),
        date: _date,
        photoUrls: urlsOnly,
      );
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
    final groupText =
    (widget.record.group.name.isEmpty) ? 'Group' : 'Group';

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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
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
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
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
                        return _AddPhotoTile(onTap: _pickPhotosFromGallery); // ✅ 갤러리 호출
                      }
                      final path = _photoPathsOrUrls[index - 1].trim();
                      final isHttp = _isHttpUrl(path);
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: path.isEmpty
                                  ? const _PhotoPlaceholder()
                                  : (isHttp
                                  ? Image.network(
                                path,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const _PhotoPlaceholder(),
                              )
                                  : Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const _PhotoPlaceholder(),
                              )),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _photoPathsOrUrls.removeAt(index - 1)),
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

            // ⬇️ 스크롤 안으로 들어온 CANCEL / SAVE
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
