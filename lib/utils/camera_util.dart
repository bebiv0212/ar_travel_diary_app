import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:joljak/utils/photo_exif.dart'; // ✅ EXIF GPS 읽기

final ImagePicker _picker = ImagePicker();

enum _PreviewAction { use, retake, cancel }

/// 카메라 열어 사진 한 장 촬영(재촬영 가능).
/// - [사진 사용] → 파일 경로(String) 반환
/// - [닫기]     → null 반환
/// - [다시 찍기] → 카메라 재실행(루프)
Future<String?> openCamera(BuildContext context) async {
  try {
    while (true) {
      final XFile? shot = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 2048,
        imageQuality: 95,
      );
      if (shot == null) return null; // 사용자가 촬영 자체를 취소

      // ✅ EXIF에서 위치 읽기 (있으면 표시)
      final gps = await readPhotoGps(shot.path);

      // 미리보기 다이얼로그: use/retake/cancel 선택
      final _PreviewAction? action = await showDialog<_PreviewAction>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(File(shot.path), fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),

                // 위치 정보
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      gps == null ? Icons.location_off_outlined : Icons.location_on_outlined,
                      size: 18,
                      color: gps == null ? Colors.grey : Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        gps == null
                            ? '위치 정보가 없습니다.'
                            : '위치: ${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: gps == null ? Colors.grey : Colors.black87,
                          fontWeight: gps == null ? FontWeight.w400 : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 파일명(선택)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    shot.name,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),

                // 버튼들: 닫기 / 다시 찍기 / 사진 사용
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, _PreviewAction.cancel),
                        child: const Text('닫기'),
                      ),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, _PreviewAction.retake),
                        child: const Text('다시 찍기', style: TextStyle(fontSize: 12),),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, _PreviewAction.use),
                        child: const Text('사진 사용', style: TextStyle(fontSize: 12),),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (action == _PreviewAction.use) {
        return shot.path; // ✅ 확정 사용
      } else if (action == _PreviewAction.cancel) {
        return null; // 닫기
      } else if (action == _PreviewAction.retake) {
        // 재촬영: 직전 사진 임시파일 삭제 시도 후 루프 계속
        try { await File(shot.path).delete(); } catch (_) {}
        continue;
      } else {
        // 방어적 폴백
        return null;
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라 실행 실패: $e')),
      );
    }
    return null;
  }
}
