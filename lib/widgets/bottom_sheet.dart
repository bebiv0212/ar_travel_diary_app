import 'package:flutter/material.dart';
import 'package:joljak/widgets/bottom_sheet_record.dart';

class MyBottomSheet extends StatelessWidget {
  const MyBottomSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2),
          ],
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
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
            const SizedBox(height: 12)
            ,
            BottomSheetRecord()
          ],
        ),
      ),
    );
  }
}
