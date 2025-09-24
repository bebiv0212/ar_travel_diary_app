import 'package:flutter/material.dart';

Future<void> showUploadProgressDialog(
    BuildContext context, {
      required ValueNotifier<double> progress,
    }) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (ctx, v, __) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('업로드 중...'),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: v > 0 && v <= 1 ? v : null),
                const SizedBox(height: 8),
                Text(v > 0 ? '${(v * 100).toStringAsFixed(0)} %' : '네트워크 준비...'),
              ],
            ),
          ),
        ),
      );
    },
  );
}
