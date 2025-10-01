import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:joljak/widgets/map_widgets/recode_create_dialog.dart';
import 'package:joljak/utils/camera_util.dart';
import '../../utils/image_compress.dart';
import '../../utils/photo_exif.dart';
import '../../utils/local_media_store.dart'; // ✅ 로컬로 영구복사
// 업로드/서버 연결 플로우는 이번 로컬 모드에선 사용 안 함
// import '../../api/uploads_api.dart';
import '../../api/trip_records_api.dart';

class MenuPill extends StatelessWidget {
  const MenuPill({
    super.key,
    this.width = 50,
    this.itemHeight = 60,
    this.elevation = 10,
  });

  final double width;
  final double itemHeight;
  final double elevation;

  Future<bool> _ensureCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라 권한이 필요합니다. 설정에서 허용해 주세요.')),
      );
      return false;
    }
    if (status.isPermanentlyDenied) {
      final go = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('권한 필요'),
          content: const Text('설정에서 카메라 권한을 허용해야 촬영이 가능합니다. 설정으로 이동할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('설정으로 이동')),
          ],
        ),
      );
      if (go == true) await openAppSettings();
      return false;
    }
    return false;
  }

  Future<String?> _captureAndSaveLocal(BuildContext context) async {
    final granted = await _ensureCameraPermission(context);
    if (!granted) return null;

    final shotPath = await openCamera(context);
    if (shotPath == null) return null;

    // (선택) 위치 안내 스낵바
    final gps = await readPhotoGps(shotPath);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(gps == null ? '이 사진에는 위치 정보가 없습니다.' :
        '위치: ${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)}')),
      );
    }

    // 용량 최적화(웹프) → 앱 문서폴더로 영구 보관 → file:/// 경로 반환
    final compressed = await compressForUpload(shotPath);
    final localUri = await persistLocalPhoto(compressed.file);
    debugPrint('[MenuPill] local photo saved: $localUri');
    return localUri; // e.g. file:///data/user/0/.../photos/2025-09/1695800000000.webp
  }

  Future<bool> _askAttachPhoto(BuildContext context) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('사진도 첨부할까요?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Text('지금 촬영한 사진을 이 기록에 바로 포함합니다.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetCtx, false), child: const Text('나중에'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(sheetCtx, true),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('사진 첨부'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8040)),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(10);

    return Material(
      color: Colors.white,
      elevation: elevation,
      shadowColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: r),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 생성: (로컬 모드) 선촬영(선택) -> Dialog -> create(photoUrls에 file:// 경로 포함)
            _MenuPillItem(
              height: itemHeight,
              icon: Icons.add,
              label: '생성',
              onTap: () async {
                List<String>? initialLocalPhotos;
                final attach = await _askAttachPhoto(context);
                if (attach) {
                  final localUri = await _captureAndSaveLocal(context);
                  if (localUri != null) initialLocalPhotos = [localUri];
                }

                // 다이얼로그: 생성 시 photoUrls에 initialLocalPhotos 포함
                final created = await showDialog<TripRecord>(
                  context: context,
                  builder: (_) => RecordCreateDialog(initialLocalPhotoPaths: initialLocalPhotos),
                );

                if (created != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('기록이 생성되었습니다.')),
                  );
                }
              },
              borderRadius: BorderRadius.vertical(top: r.topLeft),
            ),

            const SizedBox(height: 1, child: ColoredBox(color: Colors.black)),

            // 카메라: 단독 촬영(연결 없음, 로컬 보관만)
            _MenuPillItem(
              height: itemHeight,
              icon: Icons.photo_camera,
              label: '카메라',
              onTap: () async {
                final localUri = await _captureAndSaveLocal(context);
                if (localUri != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사진이 로컬에 저장되었습니다. (기록과 연결은 생성 시에만)')),
                  );
                }
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
        width: double.infinity,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 25, color: Colors.black),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
