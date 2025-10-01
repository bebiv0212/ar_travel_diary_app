import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:joljak/widgets/map_widgets/recode_create_dialog.dart';
import 'package:joljak/utils/camera_util.dart';
import '../../api/uploads_api.dart';
import '../../utils/image_compress.dart';
import '../../utils/photo_exif.dart';
import '../common_widgets/upload_progress_dialog.dart';
import '../../api/trip_records_api.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // ✅ JPEG 지정용

class MenuPill extends StatelessWidget {
  const MenuPill({
    super.key,
    this.width = 50,
    this.itemHeight = 60,
    this.elevation = 10,
    this.onPhotosReady, // ✅ 촬영/업로드 후 지도에 바로 마커 찍기 콜백
  });

  final double width;
  final double itemHeight;
  final double elevation;

  /// ✅ 촬영/업로드 후, 지도에 마커를 찍고 싶을 때 호출
  /// 전달 형식: 로컬 파일 경로 리스트 (EXIF가 있는 JPG 경로)
  final void Function(List<String> localPhotoPaths)? onPhotosReady;

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

  /// 촬영 → (EXIF 표시) → JPEG 압축(EXIF 유지) → 업로드 → (성공 시) 지도에 마커 찍기
  Future<void> _captureCompressUploadFlow(BuildContext context, {String? recordId}) async {
    // 권한 확인
    final granted = await _ensureCameraPermission(context);
    if (!granted) return;

    // 촬영 (미리보기에서 "사진 사용" 선택한 경우에만 path 반환하도록 openCamera 구현되어 있다고 가정)
    final path = await openCamera(context);
    if (path == null) return;

    // EXIF 위치 안내(있으면 표시)
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

    // ✅ JPEG로 압축 + EXIF 유지 (WebP → JPEG)
    final compress = await compressForUpload(
      path,
      format: CompressFormat.jpeg,
      quality: 85,
      maxSide: 1600,
    );
    final beforeMb = (compress.originalBytes / (1024 * 1024)).toStringAsFixed(2);
    final afterMb  = (compress.compressedBytes / (1024 * 1024)).toStringAsFixed(2);

    // 업로드 진행률 다이얼로그
    final progress = ValueNotifier<double>(0);
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      showUploadProgressDialog(context, progress: progress);
    }

    UploadPhotoResult? upload;
    String? error;
    try {
      upload = await UploadsApi().uploadPhoto(
        compress.file, // ✅ .jpg 로 업로드됨
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

    if (error != null || upload == null) {
      // ❌ 업로드 오류: 스낵바 대신 로그로
      debugPrint('[MenuPill] 업로드 실패: ${error ?? "unknown error"}');

      // (원하면 업로드 실패여도 지도에 마커는 찍을 수 있음)
      // onPhotosReady?.call([compress.file.path]);
      return;
    }

    // ✅ 일기 ID가 있으면 사진 URL을 해당 일기에 바로 추가
    if (recordId != null) {
      try {
        await TripRecordsApi().addPhotos(
          recordId: recordId,
          urls: [upload.url],
          thumbUrls: [if ((upload.thumbUrl ?? '').isNotEmpty) upload.thumbUrl!],
        );
      } catch (e) {
        debugPrint('[MenuPill] 사진 업로드 성공, 일기 연결 실패: $e');
        // 연결 실패여도 지도 마커는 가능
      }
    }

    // ✅ 최종: 지도에 마커 찍기 (EXIF가 보존된 로컬 jpg 경로를 넘김)
    onPhotosReady?.call([compress.file.path]);

    // 성공 안내
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('압축 ${beforeMb}MB → ${afterMb}MB, 업로드${recordId != null ? " 및 일기 연결" : ""} 완료!')),
    );
  }

  /// "사진도 첨부할까요?" 모달 (레코드 생성 후 즉시 첨부 흐름)
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
              const Text('방금 만든 여행 기록에 사진을 바로 추가할 수 있어요.', style: TextStyle(color: Colors.black54)),
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
            // 생성: 레코드 생성 후 첨부 여부 묻고 → 촬영/업로드 → 일기 연결 + 지도 마커
            _MenuPillItem(
              height: itemHeight,
              icon: Icons.add,
              label: '생성',
              onTap: () async {
                final created = await showDialog<TripRecord>(
                  context: context,
                  builder: (_) => const RecordCreateDialog(),
                );

                if (created != null) {
                  if (!context.mounted) return;
                  final attach = await _askAttachPhoto(context);
                  if (attach && context.mounted) {
                    await _captureCompressUploadFlow(context, recordId: created.id);
                  }
                }
              },
              borderRadius: BorderRadius.vertical(top: r.topLeft),
            ),

            const SizedBox(height: 1, child: ColoredBox(color: Colors.black)),

            // 카메라: 단독 촬영/업로드 → 지도 마커
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
