import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:joljak/utils/photo_exif.dart'; // readPhotoGps

class PhotoPoint {
  final String path; // 로컬 파일 경로(또는 file://)
  final double lat;
  final double lng;
  PhotoPoint({required this.path, required this.lat, required this.lng});
}

/// 'file://...' → 실제 파일 경로로
String _toFsPath(String src) {
  if (src.startsWith('file://')) return src.substring('file://'.length);
  return src;
}

/// 로컬 사진 경로들에서 EXIF GPS를 읽어 좌표가 있는 것만 반환
Future<List<PhotoPoint>> readGpsFromLocalPhotos(List<String> localPaths) async {
  final points = <PhotoPoint>[];
  final futures = localPaths.map((p) async {
    try {
      final fsPath = _toFsPath(p);
      if (!await File(fsPath).exists()) return null;
      final gps = await readPhotoGps(fsPath);
      if (gps == null) return null;
      return PhotoPoint(path: fsPath, lat: gps.latitude, lng: gps.longitude);
    } catch (e) {
      debugPrint('[photo_markers] read EXIF failed for $p: $e');
      return null;
    }
  });
  final results = await Future.wait(futures);
  for (final r in results) {
    if (r != null) points.add(r);
  }
  return points;
}

/// Kakao Map 마커 리스트 생성 (인포윈도우 없음)
List<Marker> buildMarkersFromPhotoPoints(List<PhotoPoint> points) {
  final markers = <Marker>[];
  for (int i = 0; i < points.length; i++) {
    final pt = points[i];
    markers.add(
      Marker(
        markerId: 'photo_$i',
        latLng: LatLng(pt.lat, pt.lng),
        width: 32,
        height: 42,
      ),
    );
  }
  return markers;
}

/// 지도에 마커 추가 (기존 마커 유지)
Future<void> addPhotoMarkersToMap(
    KakaoMapController controller,
    List<Marker> markers,
    ) async {
  if (markers.isEmpty) return;
  await controller.addMarker(markers: markers);
}
