// lib/screens/ar_camera_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:joljak/providers/ar_camera_provider.dart';
import 'package:joljak/screens/ar_camera_screen.dart';

class ArCameraPage extends StatelessWidget {
  const ArCameraPage({super.key, this.maxPick = 10, this.onPhotosSelected});

  final int maxPick;
  final void Function(List<File> files)? onPhotosSelected;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ArCameraProvider()..initialize(),
      // Provider "아래" 컨텍스트에서 화면을 빌드
      builder: (context, _) => ArCameraScreen(
        maxPick: maxPick,
        onPhotosSelected: onPhotosSelected,
      ),
    );
  }
}
