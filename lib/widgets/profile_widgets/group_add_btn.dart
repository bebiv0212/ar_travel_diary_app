import 'package:flutter/material.dart';
import 'group_create_btn.dart';

class GroupAddBtn extends StatelessWidget {
  const GroupAddBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          // 그룹 생성 모달 표시
          final result = await showDialog<GroupCreateBtn>(
            context: context,
            barrierDismissible: true, // 바깥 터치로 닫기 허용 (원치 않으면 false)
            builder: (_) => const GroupCreateBtn(),
          );

          if (result != null) {
            // final api = GroupApi(); // 직접 만든 API 클래스
            // final created = await api.create(
            //   name: result.name,
            //   colorHex: colorToHex(result.color),
            // );
            // if (context.mounted) {
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     SnackBar(content: Text('그룹 "${created.name}" 생성 완료')),
            //   );
            // }
            debugPrint("그룹 생성");
          }

        },
        child: Ink(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, size: 100),
              SizedBox(height: 8),
              Text(
                '그룹 추가하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
