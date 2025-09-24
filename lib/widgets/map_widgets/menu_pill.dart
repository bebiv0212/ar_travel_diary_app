import 'package:flutter/material.dart';
import 'package:joljak/widgets/map_widgets/recode_create_dialog.dart';

class MenuPill extends StatelessWidget {
  const MenuPill({
    super.key,
    required this.onCreate,
    required this.onCamera,
    this.width = 50,
    this.itemHeight = 60,
    this.elevation = 10,
  });

  final VoidCallback onCreate;
  final VoidCallback onCamera;
  final double width; // 캡슐 폭
  final double itemHeight; // 각 버튼 높이
  final double elevation; // 그림자

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(10);

    return Material(
      color: Colors.white,
      elevation: elevation,
      shadowColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: r),
      clipBehavior: Clip.antiAlias, // 테두리 안으로 리플/자식 클립
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width), // ✅ 폭은 유한값
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ 높이는 내용만큼
          children: [
            _MenuPillItem(
              height: itemHeight,
              icon: Icons.add,
              label: '생성',
              onTap: () async {
                final ok = await showDialog(
                  context: context,
                  builder: (_) => const RecordCreateDialog(), // ✅ 인자 없이
                );
                if (ok == true) {
                  // 새 기록 반영
                }
              },
              borderRadius: BorderRadius.vertical(top: r.topLeft),
            ),
            const SizedBox(
              // 가는 구분선
              height: 1,
              child: ColoredBox(color: Colors.black),
            ),
            _MenuPillItem(
              height: itemHeight,
              icon: Icons.photo_camera,
              label: '카메라',
              onTap: onCamera,
              borderRadius: BorderRadius.vertical(bottom: r.bottomLeft),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuPillItem extends StatelessWidget {
  const _MenuPillItem({
    required this.height,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.borderRadius,
  });

  final double height;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: SizedBox(
        width: double.infinity, // 부모가 이미 폭을 고정해줌
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 25, color: Colors.black),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
