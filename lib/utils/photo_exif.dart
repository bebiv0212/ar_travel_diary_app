// lib/utils/photo_exif.dart
import 'dart:io';
import 'package:exif/exif.dart';

class PhotoGps {
  final double latitude;
  final double longitude;
  const PhotoGps(this.latitude, this.longitude);
}

double _dmsToDeg(List<Ratio> dms) {
  // d,m,s 각각이 Ratio (분모/분자) → double로 변환
  final d = dms[0].toDouble();
  final m = dms[1].toDouble();
  final s = dms[2].toDouble();
  return d + (m / 60.0) + (s / 3600.0);
}

List<Ratio> _extractRatios(IfdTag tag) {
  final v = tag.values;
  if (v is IfdRatios) return v.ratios;        // 가장 정상 경로
  // 방어적으로 toList()에서 Ratio만 뽑기
  return v.toList().whereType<Ratio>().toList();
}

/// 사진 파일 경로에서 EXIF GPS 읽기. 없으면 null 반환
Future<PhotoGps?> readPhotoGps(String filePath) async {
  final bytes = await File(filePath).readAsBytes();
  final tags = await readExifFromBytes(bytes);

  final latTag = tags['GPS GPSLatitude'];
  final latRef = tags['GPS GPSLatitudeRef']?.printable; // 'N' | 'S'
  final lonTag = tags['GPS GPSLongitude'];
  final lonRef = tags['GPS GPSLongitudeRef']?.printable; // 'E' | 'W'

  if (latTag == null || lonTag == null || latRef == null || lonRef == null) {
    return null; // GPS 태그가 없음
  }

  final lat = _dmsToDeg(_extractRatios(latTag));
  final lon = _dmsToDeg(_extractRatios(lonTag));

  final signedLat = latRef.toUpperCase().startsWith('S') ? -lat : lat;
  final signedLon = lonRef.toUpperCase().startsWith('W') ? -lon : lon;

  return PhotoGps(signedLat, signedLon);
}
