import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:joljak/widgets/map_widgets/recode_create_dialog.dart';
import 'package:joljak/utils/camera_util.dart';
import '../../api/uploads_api.dart';
import '../../utils/image_compress.dart';
import '../../utils/photo_exif.dart';
import '../common_widgets/upload_progress_dialog.dart';

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

  // ───────────────────────── helpers ─────────────────────────

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
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('설정을 열 수 없습니다. 직접 권한을 허용해 주세요.')),
          );
        }
      }
      return false;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라 권한 상태: ${status.toString()}')),
      );
    }
    return false;
  }

  /// "사진도 첨부할까요?" 모달
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
              const Text('방금 만든 여행 기록에 사진을 바로 추가할 수 있어요.',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx, false),
                      child: const Text('나중에'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(sheetCtx, true),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('사진 첨부'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8040)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return res == true;
  }

  /// 촬영 → (EXIF 표시) → 압축 → 진행률 보여주며 업로드
  Future<void> _captureCompressUploadFlow(BuildContext context) async {
    // 권한
    final granted = await _ensureCameraPermission(context);
    if (!granted) return;

    // 촬영 + 미리보기(위치 표시)
    final path = await openCamera(context);
    if (path == null) return;

    // (선택) EXIF GPS 안내 스낵바—미리보기에서 이미 보여주지만 추가로 알림 원하면 사용
    final gps = await readPhotoGps(path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gps == null
                ? '이 사진에는 위치 정보가 없습니다.'
                : '위치: ${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    }

    // 압축
    final compress = await compressForUpload(path);
    final beforeMb = (compress.originalBytes / (1024 * 1024)).toStringAsFixed(2);
    final afterMb  = (compress.compressedBytes / (1024 * 1024)).toStringAsFixed(2);

    // 업로드 진행률 다이얼로그
    final progress = ValueNotifier<double>(0);
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      showUploadProgressDialog(context, progress: progress);
    }

    String? error;
    try {
      await UploadsApi().uploadPhoto(
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('압축 ${beforeMb}MB → ${afterMb}MB, 업로드 완료!')),
    );

    // TODO: 업로드 결과를 방금 만든 기록에 연결하려면
    // - TripRecordsApi에 사진 추가 엔드포인트가 있으면 여기서 호출
    // - 없다면, 생성 다이얼로그에서 create 응답으로 id를 받아 저장해 두고 여기서 PUT으로 photoUrls 추가
  }

  // ───────────────────────── UI ─────────────────────────

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
            // 생성
            _MenuPillItem(
              height: itemHeight,
              icon: Icons.add,
              label: '생성',
              onTap: () async {
                final ok = await showDialog(
                  context: context,
                  builder: (_) => const RecordCreateDialog(),
                );

                if (ok == true) {
                  // ✅ 생성 성공: 여기서는 "새로고침"만! (카메라 자동 실행 금지)
                  // TODO: 목록/지도 갱신 콜백이 있다면 호출

                  // 사진 첨부 여부 묻기
                  if (!context.mounted) return;
                  final attach = await _askAttachPhoto(context);
                  if (attach && context.mounted) {
                    await _captureCompressUploadFlow(context);
                  }
                }
              },
              borderRadius: BorderRadius.vertical(top: r.topLeft),
            ),

            const SizedBox(height: 1, child: ColoredBox(color: Colors.black)),

            // 카메라
            _MenuPillItem(
              height: itemHeight,
              icon: Icons.photo_camera,
              label: '카메라',
              onTap: () async {
                await _captureCompressUploadFlow(context);
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
