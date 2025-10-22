// lib/screens/ar_camera_screen.dart
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:joljak/providers/ar_camera_provider.dart';
import 'package:joljak/screens/gallery_picker_screen.dart';

import '../widgets/ar_camera_widgets/selected_photos_sheet.dart';

class ArCameraScreen extends StatelessWidget {
  const ArCameraScreen({
    super.key,
    this.maxPick = 10,
    this.onPhotosSelected, // 선택 결과를 외부로 보내고 싶으면 사용 (없으면 바텀시트 표시)
  });

  final int maxPick;
  final void Function(List<File> files)? onPhotosSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArCameraProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // 카메라 미리보기
            Positioned.fill(child: _CameraView()),

            // 오버레이(나침반/수평선)
            Positioned.fill(
              child: _ArOverlay(
                heading: p.heading,
                pitch: p.pitch,
                position: p.position,
              ),
            ),

            // ✅ 오른쪽 사이드 액션 버튼들
            Positioned(
              right: 12,
              top: MediaQuery.of(context).padding.top + 24,
              child: Column(
                children: [
                  // 사진 선택 버튼 (갤러리로)
                  _SideBtn(
                    icon: Icons.photo_library,
                    label: '사진',
                    onTap: () async {
                      final files = await GalleryPickerScreen.open(context, maxPick: maxPick);
                      if (files == null || files.isEmpty || !context.mounted) return;

                      if (onPhotosSelected != null) {
                        onPhotosSelected!(files);
                        return;
                      }
                      // 기본: 바텀시트로 미리보기
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => SelectedPhotosSheet(files: files),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // (옵션) 토치 토글 – 보기 전용이라도 손전등은 유용
                  if (p.hasFlash)
                    _SideBtn(
                      icon: p.torchOn ? Icons.flash_on : Icons.flash_off,
                      label: '플래시',
                      onTap: () => context.read<ArCameraProvider>().toggleTorch(),
                    ),
                  const SizedBox(height: 10),

                  // (옵션) 전/후면 전환
                  _SideBtn(
                    icon: Icons.cameraswitch,
                    label: '전환',
                    onTap: () => context.read<ArCameraProvider>().switchCamera(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArCameraProvider>();
    if (!p.isReady) {
      final err = p.error;
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(
          err ?? '카메라 준비 중…',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    return CameraPreview(p.controller!);
  }
}

class _ArOverlay extends StatelessWidget {
  const _ArOverlay({
    required this.heading,
    required this.pitch,
    required this.position,
  });

  final double heading; // 0~360
  final double pitch;   // 근사치
  final Position? position;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizonY = size.height * (0.5 - (pitch.clamp(-30, 30) / 60.0));

    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          // 수평선
          Positioned(
            left: 0, right: 0, top: horizonY,
            child: Opacity(opacity: 0.5, child: Container(height: 1, color: Colors.white70)),
          ),
          // 나침반(헤딩)
          Positioned(
            top: MediaQuery.of(context).padding.top + 64, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: Text('Heading ${heading.toStringAsFixed(0)}°',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideBtn extends StatelessWidget {
  const _SideBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
