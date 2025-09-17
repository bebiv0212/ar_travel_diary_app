import 'package:flutter/material.dart';

/// 다이얼로그에서 반환할 결과
class GroupCreateResult {
  final String name;
  final Color color;
  GroupCreateResult({required this.name, required this.color});
}

class GroupCreateBtn extends StatefulWidget {
  const GroupCreateBtn({super.key});

  @override
  State<GroupCreateBtn> createState() => _GroupCreateBtnState();
}

class _GroupCreateBtnState extends State<GroupCreateBtn> {
  final _nameCtrl = TextEditingController();
  int _selected = 0;

  // 팔레트 (원하면 수정)
  static const _palette = <Color>[
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
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹 이름을 입력해주세요')),
      );
      return;
    }
    // 다이얼로그 닫으면서 값 반환
    Navigator.of(context, rootNavigator: true).pop(
      GroupCreateResult(name: name, color: _palette[_selected]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom, // 키보드 대응
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 타이틀 + 닫기
              Stack(
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '그룹 생성',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 그룹 이름
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: '그룹 이름',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // 섹션 타이틀
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '포인트 색상',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 색상 팔레트
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: GridView.builder(
                  itemCount: _palette.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (_, i) {
                    final c = _palette[i];
                    final selected = i == _selected;
                    return InkWell(
                      onTap: () => setState(() => _selected = i),
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black12.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.06),
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
              const SizedBox(height: 16),

              // 생성 버튼
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8040),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    '생성',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
