import 'package:flutter/material.dart';
import 'group_create_btn.dart';
import 'package:joljak/api/group_api.dart'; // 경로를 프로젝트에 맞게 조정하세요

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
          // 그룹 생성 모달 표시 (결과 타입: GroupCreateResult)
          final result = await showDialog<GroupCreateResult>(
            context: context,
            barrierDismissible: true,
            builder: (_) => const GroupCreateBtn(),
          );

          if (result != null) {
            try {
              final api = GroupApi();
              final created = await api.create(
                name: result.name,
                color: result.color, // 내부에서 '#RRGGBB'로 변환해서 전송
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('그룹 "${created.name}" 생성 완료')),
              );

              // (선택) 상위에서 목록을 새로고침해야 한다면:
              //  - 콜백 패턴(onCreated)으로 올리거나
              //  - Provider/Bloc으로 리스트를 갱신하세요.
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('생성 실패: $e')),
              );
            }
          }
        },
        child: Ink(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
