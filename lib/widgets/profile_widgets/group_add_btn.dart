// lib/widgets/profile_widgets/group_add_btn.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'group_create_btn.dart';
import 'package:joljak/providers/group_provider.dart';

class GroupAddBtn extends StatelessWidget {
  const GroupAddBtn({super.key});
  static const double tileSize = 72;
  static const BorderRadius kRadius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ⬇️ 고정 크기 대신 Expanded + AspectRatio(1)
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Material(
              color: Colors.transparent,
              borderRadius: kRadius,
              child: InkWell(
                borderRadius: kRadius,
                onTap: () async {
                  final r = await showDialog<GroupCreateResult>(
                    context: context,
                    barrierDismissible: true,
                    builder: (_) => const GroupCreateBtn(),
                  );
                  if (r != null) {
                    await context.read<GroupProvider>().create(r.name, r.color);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('그룹 "${r.name}" 생성 완료')),
                      );
                    }
                  }
                },
                child: Ink(
                  // ⬇️ 고정 width/height 제거 (부모 비율/높이 따름)
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: kRadius,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(child: Icon(Icons.add, size: 30)), // 32→30(선택)
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4), // 6→4
        SizedBox(
          width: tileSize + 4,
          child: const Text(
            '새 그룹 추가',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, height: 1.0),
          ),
        ),
      ],
    );
  }
}
