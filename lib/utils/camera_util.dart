import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:joljak/utils/photo_exif.dart'; // ✅ EXIF GPS 읽기

final ImagePicker _picker = ImagePicker();

/// 카메라 열어 사진 한 장 촬영.
/// 촬영 취소하면 null, 성공하면 파일 경로 반환.
Future<String?> openCamera(BuildContext context) async {
  try {
    final XFile? shot = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 2048,      // 필요시 조절
      imageQuality: 95,    // 1~100
    );
    if (shot == null) return null; // 사용자가 취소

    // ✅ EXIF에서 위치 읽기 (있으면 표시)
    final gps = await readPhotoGps(shot.path);

    // 미리보기 다이얼로그
    await showDialog(
      context: context,
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

              // ✅ 여기서 사진 아래에 위치 정보 표시
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
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('닫기'),
                  ),
                ],
              ),

              // 파일명(선택)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  shot.name,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // TODO: 업로드/다음 화면 이동 등 원하는 처리
    return shot.path;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라 실행 실패: $e')),
      );
    }
    return null;
  }
}
