import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:joljak/widgets/map_widgets/recode_create_dialog.dart';
import 'package:joljak/utils/camera_util.dart';
import '../../api/uploads_api.dart';
import '../../utils/image_compress.dart';
import '../../utils/photo_exif.dart';
import '../common_widgets/upload_progress_dialog.dart'; // ✅ 촬영 유틸 임포트

class MenuPill extends StatelessWidget {
  const MenuPill({
    super.key,
    this.width = 50,
    this.itemHeight = 60,
    this.elevation = 10,
  });

  final double width; // 캡슐 폭
  final double itemHeight; // 각 버튼 높이
  final double elevation; // 그림자

  // ✅ 카메라 권한 보장 유틸
  Future<bool> _ensureCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;

    // 이미 허용
    if (status.isGranted) return true;

    // 최초 요청/거부 후 재요청
    status = await Permission.camera.request();
    if (status.isGranted) return true;

    // 거부(일시적)
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라 권한이 필요합니다. 설정에서 허용해 주세요.')),
      );
      return false;
    }

    // 영구 거부(다시 묻지 않음)
    if (status.isPermanentlyDenied) {
      final go = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('권한 필요'),
          content: const Text('설정에서 카메라 권한을 허용해야 촬영이 가능합니다. 설정으로 이동할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('설정으로 이동'),
            ),
          ],
        ),
      );

      if (go == true) {
        final opened = await openAppSettings();
        if (!opened) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('설정을 열 수 없습니다. 직접 권한을 허용해 주세요.')),
          );
        }
      }
      return false;
    }

    // 그 외(제한 등)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('카메라 권한 상태: ${status.toString()}')),
    );
    return false;
  }

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
                  // TODO: 새 기록 반영(리스트/지도 새로고침 등)
                }
                final path = await openCamera(context);
                if (path != null) {
                  final gps = await readPhotoGps(path);
                  if (gps == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이 사진에는 위치 정보가 없습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('위치: ${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)}')),
                    );
                  }
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
              onTap: () async {
                final granted = await _ensureCameraPermission(context);
                if (!granted) return;

                // 1) 촬영
                final path = await openCamera(context);
                if (path == null) return;

                // 2) 로컬 압축 (WebP, 1600px 한정)
                final compress = await compressForUpload(path);
                final beforeMb = (compress.originalBytes / (1024 * 1024)).toStringAsFixed(2);
                final afterMb  = (compress.compressedBytes / (1024 * 1024)).toStringAsFixed(2);

                // 3) 진행률 다이얼로그 띄우고 업로드
                final progress = ValueNotifier<double>(0);
                // ignore: use_build_context_synchronously
                showUploadProgressDialog(context, progress: progress);

                UploadPhotoResult? result;
                String? error;
                try {
                  result = await UploadsApi().uploadPhoto(
                    compress.file,
                    onSendProgress: (sent, total) {
                      if (total > 0) progress.value = sent / total;
                    },
                  );
                } catch (e) {
                  error = e.toString();
                } finally {
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(); // 진행률 다이얼로그 닫기
                  }
                }

                if (!context.mounted) return;

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('업로드 실패: $error')),
                  );
                  return;
                }

                // 4) 결과 안내
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('압축 ${beforeMb}MB → ${afterMb}MB, 업로드 완료!')),
                );

                // 필요하면 여기서 result!.url / thumbUrl 을 다음 로직으로 넘겨 사용
                // ex) TripRecordsApi().create(photoUrls: [result!.url], ...)
              },
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
  final Future<void> Function() onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
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
