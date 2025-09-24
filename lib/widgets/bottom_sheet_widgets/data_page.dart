import 'package:flutter/material.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/bottom_sheet_record.dart';
import 'seed_records.dart';

class DataPage extends StatefulWidget {
  final Record record;
  const DataPage({super.key, required this.record});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  bool isEditing = false;
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.record.title);
    contentController = TextEditingController(text: widget.record.description);
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void saveChanges() {
    // 여기에 저장 로직 추가 (예: DB 업데이트, 상태 변경 등)
    setState(() {
      isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("기록이 저장되었습니다.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("기록 상세"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            onPressed: toggleEdit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isEditing
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "제목"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: "내용"),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveChanges,
              child: const Text("저장"),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.record.title,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(widget.record.description,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}