import 'package:flutter/material.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/bottom_sheet_record.dart';

class MyBottomSheet extends StatelessWidget {
  const MyBottomSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Material(
      // Scaffold 대신 Material 사용: 라운드/그림자/클리핑 여기서 처리
      elevation: 12,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias, // 라운드 안쪽으로 내용 클립
      child: SafeArea(
        top: false, // 상단 노치 영역까지 높이 늘어나지 않도록
        child: ListView(
          controller: scrollController, // ✅ 반드시 연결
          padding: const EdgeInsets.all(16),
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              "나의 기록",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 내용
            const BottomSheetRecord(),
          ],
        ),
      ),
    );
  }
}
