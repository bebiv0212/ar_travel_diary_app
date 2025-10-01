import 'package:flutter/material.dart';
import 'package:joljak/theme/app_colors.dart';

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
    Navigator.of(context, rootNavigator: true).pop(
      GroupCreateResult(name: name, color: _palette[_selected]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.of(context);
    final kbVisible = view.viewInsets.bottom > 0;

    // 사진 #2 느낌으로: 키보드가 보일 때만 화면 높이의 18%만 위로
    const liftFraction = -0.18; // 더 올리고 싶으면 -0.22~-0.25로, 덜 올리면 -0.12~-0.15로

    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true, // 시스템이 다이얼로그를 강제로 밀어올리지 않도록
      child: AnimatedSlide(
        offset: kbVisible ? const Offset(0, liftFraction) : Offset.zero,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // 고정
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: view.size.height * 0.85),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), // 내부는 고정 패딩
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black,
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
                          backgroundColor: AppColors.mainColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          '생성',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
