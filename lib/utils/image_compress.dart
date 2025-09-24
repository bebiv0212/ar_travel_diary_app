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

/// 업로드 최적화 압축:
/// - 긴 변 기준 maxSide(기본 1600)으로만 축소(작으면 업스케일 X)
/// - WebP 품질 80
/// - EXIF 보존 시도(keepExif: true)
Future<CompressResult> compressForUpload(
    String inputPath, {
      int maxSide = 1600,
      int quality = 80,
    }) async {
  final input = File(inputPath);
  final originalBytes = await input.length();

  // 1) 원본 크기 파악 (image 패키지 사용: flutter_image_compress 2.4.0에선 getImageProperties 미사용)
  int srcW = 0, srcH = 0;
  try {
    final srcBytes = await input.readAsBytes();
    final decoded = img.decodeImage(srcBytes);
    if (decoded != null) {
      srcW = decoded.width;
      srcH = decoded.height;
    }
  } catch (_) {
    // HEIC 등 디코딩 실패 시 0으로 두고 minWidth/minHeight에 maxSide 넣어 처리
  }

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

  // 3) WebP 압축 (compressWithFile은 2.4.0에서 OK)
  final tempDir = await getTemporaryDirectory();
  final outPath = p.join(
    tempDir.path,
    '${DateTime.now().millisecondsSinceEpoch}.webp',
  );

  // srcW/H를 못 구한 경우(minWidth/minHeight가 0이면 오류) → 안전하게 maxSide로 가드
  final minW = (targetW > 0) ? targetW : maxSide;
  final minH = (targetH > 0) ? targetH : maxSide;

  Uint8List? outBytes = await FlutterImageCompress.compressWithFile(
    inputPath,
    format: CompressFormat.webp,
    quality: quality,      // 1~100
    minWidth: minW,        // 0 금지: 반드시 양수
    minHeight: minH,       // 0 금지: 반드시 양수
    keepExif: true,        // EXIF 보존 시도
    // rotate, autoCorrectionAngle 등 필요시 추가
  );

  final outFile = outBytes != null
      ? await File(outPath).writeAsBytes(outBytes)
      : input; // 실패 시 원본 그대로 사용

  final compressedBytes = await outFile.length();
  return CompressResult(outFile, originalBytes, compressedBytes);
}
