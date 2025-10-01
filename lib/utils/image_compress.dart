import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

class CompressResult {
  final File file;
  final int originalBytes;
  final int compressedBytes;
  CompressResult(this.file, this.originalBytes, this.compressedBytes);
}

String _extForFormat(CompressFormat format) => switch (format) {
  CompressFormat.jpeg => '.jpg',
  CompressFormat.png  => '.png',
  CompressFormat.webp => '.webp',
  CompressFormat.heic => '.heic',
// CompressFormat.heif => '.heif',
};


/// 업로드 최적화 압축 (기본: JPEG, EXIF 보존)
/// - 긴 변 기준 maxSide(기본 1600) 축소(작으면 업스케일 X)
/// - JPEG 품질 85
/// - EXIF 보존(keepExif: true, JPEG/HEIC에서 유효)
Future<CompressResult> compressForUpload(
    String inputPath, {
      int maxSide = 1600,
      int quality = 85,
      CompressFormat format = CompressFormat.jpeg, // ✅ 기본 JPEG
    }) async {
  final input = File(inputPath);
  final originalBytes = await input.length();

  // 1) 원본 크기 파악
  int srcW = 0, srcH = 0;
  try {
    final srcBytes = await input.readAsBytes();
    final decoded = img.decodeImage(srcBytes);
    if (decoded != null) {
      srcW = decoded.width;
      srcH = decoded.height;
    }
  } catch (_) {}

  // 2) 목표 크기(업스케일 방지)
  int targetW = srcW;
  int targetH = srcH;
  final needResize = (srcW > maxSide) || (srcH > maxSide);
  if (needResize && srcW > 0 && srcH > 0) {
    if (srcW >= srcH) {
      targetW = maxSide;
      targetH = ((srcH * maxSide) / srcW).round();
    } else {
      targetH = maxSide;
      targetW = ((srcW * maxSide) / srcH).round();
    }
  }

  // 3) 압축
  final tempDir = await getTemporaryDirectory();
  final outPath = p.join(
    tempDir.path,
    '${DateTime.now().millisecondsSinceEpoch}${_extForFormat(format)}', // ✅ 확장자 동기화
  );

  final minW = (targetW > 0) ? targetW : maxSide;
  final minH = (targetH > 0) ? targetH : maxSide;

  Uint8List? outBytes = await FlutterImageCompress.compressWithFile(
    inputPath,
    format: format,        // ✅ JPEG 기본
    quality: quality,
    minWidth: minW,
    minHeight: minH,
    keepExif: true,        // ✅ EXIF 보존
  );

  final outFile = outBytes != null
      ? await File(outPath).writeAsBytes(outBytes)
      : input; // 실패 시 원본 사용

  final compressedBytes = await outFile.length();
  return CompressResult(outFile, originalBytes, compressedBytes);
}
