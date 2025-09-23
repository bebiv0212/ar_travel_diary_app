import 'package:flutter/material.dart';
import '../../api/group_api.dart';
import '../../api/memories_api.dart';
import '../common_widgets/form_decoration.dart';
import '../profile_widgets/group_create_btn.dart';

class RecordCreateDialog extends StatefulWidget {
  const RecordCreateDialog({
    super.key,
    this.anchor, // 좌표는 제거, anchor는 선택
  });

  final String? anchor;

  @override
  State<RecordCreateDialog> createState() => _RecordCreateDialogState();
}

class _RecordCreateDialogState extends State<RecordCreateDialog> {
  final _pinCtrl  = TextEditingController();
  final _dateCtrl = TextEditingController();
  DateTime? _selectedDate;

  Group? _selectedGroup;
  List<Group> _groups = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGroups() async {
    setState(() => _loading = true);
    try {
      final api = GroupApi();
      final list = await api.listMyGroups();
      setState(() {
        _groups = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 불러오기 실패: $e')),
      );
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = _fmtDate(picked);
      });
    }
  }

  Future<void> _onSelectGroup(dynamic value) async {
    if (value == '__create__') {
      final result = await showDialog<GroupCreateResult>(
        context: context,
        builder: (_) => const GroupCreateBtn(),
      );
      if (result != null) {
        try {
          final api = GroupApi();
          final newGroup = await api.create(name: result.name, color: result.color);
          await _fetchGroups();
          setState(() => _selectedGroup = newGroup);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('그룹 생성 실패: $e')));
        }
      }
    } else {
      setState(() => _selectedGroup = value as Group);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_pinCtrl.text.trim().isEmpty || _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('핀 이름과 그룹을 입력해주세요.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = MemoriesApi();
      await api.create(
        groupId: _selectedGroup!.id,
        text: _pinCtrl.text.trim(),
        anchor: widget.anchor,
        tags: const [],
        favorite: false,
        visibility: 'private',
        date: _selectedDate,
        // ✅ latitude/longitude는 전달하지 않음
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기록 생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('여행 기록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextField(
                controller: _pinCtrl,
                decoration: filledDecoration(context, hintText: '핀 이름'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _dateCtrl,
                readOnly: true,
                showCursor: false,
                onTap: _pickDate,
                decoration: filledDecoration(
                  context,
                  hintText: '날짜',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    onPressed: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<dynamic>(
                value: _selectedGroup,
                isExpanded: true,
                items: [
                  ..._groups.map((g) => DropdownMenuItem(value: g, child: Text(g.name))),
                  const DropdownMenuItem(value: '__create__', child: Text('새 그룹 생성')),
                ],
                onChanged: _onSelectGroup,
                decoration: filledDecoration(context, hintText: '그룹지정'),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(100, 48)),
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8040),
                      minimumSize: const Size(100, 48),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('생성'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
