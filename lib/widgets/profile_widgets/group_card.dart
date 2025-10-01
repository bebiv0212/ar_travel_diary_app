import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:joljak/providers/group_provider.dart';
import 'package:joljak/widgets/profile_widgets/group_add_btn.dart';

/// 그룹 카드: 탭하면 수정 다이얼로그 오픈
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.groupId,
    required this.name,
    required this.color,
  });

  final String groupId;
  final String name;
  final Color color;

  static const double tileSize = GroupAddBtn.tileSize;
  static const BorderRadius kRadius = GroupAddBtn.kRadius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: kRadius,
      onTap: () async {
        final changed = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => _GroupEditDialog(
            groupId: groupId,
            initialName: name,
            initialColor: color,
          ),
        );
        if (changed == true && context.mounted) {
          context.read<GroupProvider>().load();
        }
      },
      child: Column(
        children: [
          Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: kRadius,
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: Icon(Icons.place_rounded, color: color, size: 30),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: tileSize + 4,
            child: Text(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────
/// 수정 다이얼로그 (이름/색상 변경 + 삭제)
class _GroupEditDialog extends StatefulWidget {
  const _GroupEditDialog({
    required this.groupId,
    required this.initialName,
    required this.initialColor,
  });

  final String groupId;
  final String initialName;
  final Color initialColor;

  @override
  State<_GroupEditDialog> createState() => _GroupEditDialogState();
}

class _GroupEditDialogState extends State<_GroupEditDialog> {
  late TextEditingController _nameCtrl;
  late Color _selected;
  bool _saving = false;

  static const List<Color> _palette = [
    Color(0xFFE74C3C), // red
    Color(0xFFE91E63), // pink
    Color(0xFF8E44AD), // purple
    Color(0xFF3F51B5), // indigo
    Color(0xFF2196F3), // blue
    Color(0xFF00BCD4), // cyan
    Color(0xFF009688), // teal
    Color(0xFF2ECC71), // green
    Color(0xFF8BC34A), // light green
    Color(0xFFCDDC39), // lime
    Color(0xFFFFEB3B), // yellow
    Color(0xFFFFC107), // amber
    Color(0xFFFF9800), // orange
    Color(0xFFFF5722), // deep orange
    Color(0xFF795548), // brown
    Color(0xFF9E9E9E), // grey
    Color(0xFF607D8B), // blueGrey
    Color(0xFF673AB7), // deepPurple
    Color(0xFF03A9F4), // lightBlue
    Color(0xFF4CAF50), // green2
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _selected = widget.initialColor;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹명을 입력해주세요.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<GroupProvider>().update(
        id: widget.groupId,
        name: name,
        color: _selected,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹이 수정되었습니다.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteConfirmDialog(),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await context.read<GroupProvider>().delete(widget.groupId);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹이 삭제되었습니다.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        // ✅ 키보드가 올라오면 그 높이만큼 하단 패딩을 더해 버튼이 가려지지 않음
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + view.viewInsets.bottom,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          // 데스크톱/태블릿에서 좌우 폭 제한
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _saving ? null : _delete,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete, size: 18, color: Colors.red),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '그룹 수정',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, color: Colors.black87),
                    tooltip: '닫기',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 입력
              TextField(
                controller: _nameCtrl,
                enabled: !_saving,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: '그룹 이름',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '색상 변경',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),

              // 팔레트
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Material(
                    color: Colors.white,
                    elevation: 1.5,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        itemCount: _palette.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 시안에 맞춘 5열
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (_, i) {
                          final c = _palette[i];
                          final selected = c == _selected;

                          return InkWell(
                            onTap: _saving ? null : () => setState(() => _selected = c),
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0x0F000000), // 0x0F = 6% 불투명
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x0F000000), // 0x0F = 6% 불투명
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check, size: 20, color: Colors.white),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    '수정',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '정말로 삭제 하시겠습니까?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            // 아이콘 + 안내문 (가운데)
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.black54),
                      Positioned(
                        right: -2,
                        top: -3,
                        child: Icon(Icons.priority_high_rounded, size: 10, color: Colors.orange),
                      ),
                    ],
                  ),
                  SizedBox(width: 6),
                  Text(
                    '삭제시 그룹에 해당하는 일기도 삭제됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, height: 1.28, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('취소', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
