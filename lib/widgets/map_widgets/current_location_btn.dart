import 'package:flutter/material.dart';
import 'package:joljak/theme/app_colors.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:joljak/utils/location_access.dart';

/// 현재 위치로 "지도만 이동" + 위치 오버레이(원형) 갱신
/// - 마커는 사용하지 않음
class CurrentLocationBtn extends StatelessWidget {
  final KakaoMapController? mapController;
  final String dotCircleId;      // 작은 점(현재 위치)
  final String accCircleId;      // 정확도 반경 원
  final int zoomLevel;
  final LatLng? fallbackCenter;

  static final LatLng _defaultFallback = LatLng(37.5665, 126.9780); // 서울시청

  const CurrentLocationBtn({
    super.key,
    required this.mapController,
    this.dotCircleId = 'my_loc_dot',
    this.accCircleId = 'my_loc_acc',
    this.zoomLevel = 3,
    this.fallbackCenter,
  });

  Future<Position?> _getPosition() async {
    try {
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      );
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  Future<void> _drawLocationOverlay(
      KakaoMapController c,
      LatLng center, {
        double? accuracyMeters,
      }) async {
    // 기존 위치 원 제거
    try {
      await c.clearCircle(circleIds: [dotCircleId, accCircleId]);
    } catch (_) {}

    // 작은 점(현재 위치)
    final dot = Circle(
      circleId: dotCircleId,
      center: center,
      radius: 6, // 미터 단위(줌에 따라 보이는 크기가 달라질 수 있음)
      strokeColor: Colors.white,
      strokeOpacity: 1,
      strokeWidth: 2,
      fillColor: const Color(0xFF1976D2), // 파란 점
      fillOpacity: 1,
      zIndex: 10000,
    );

    // 정확도 반경(있을 때만)
    final List<Circle> circles = [dot];
    if (accuracyMeters != null && accuracyMeters.isFinite && accuracyMeters > 0) {
      final safeAcc = accuracyMeters.clamp(10, 300.0); // 너무 크거나 작을 때 제한
      circles.add(
        Circle(
          circleId: accCircleId,
          center: center,
          radius: safeAcc.toDouble(),
          strokeColor: const Color(0xFF1976D2),
          strokeOpacity: 0.3,
          strokeWidth: 1,
          fillColor: const Color(0xFF1976D2),
          fillOpacity: 0.10,
          zIndex: 9999,
        ),
      );
    }

    await c.addCircle(circles: circles);
  }

  Future<void> _onPressed(BuildContext context) async {
    final c = mapController;
    if (c == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도가 아직 준비되지 않았어요.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final status = await LocationAccess.ensureAll(context);
    if (!context.mounted) return;

    if (status != LocationAccessStatus.granted) {
      final msg = switch (status) {
        LocationAccessStatus.serviceDisabled =>
        '위치 서비스가 꺼져 있어 현재 위치를 가져올 수 없어요.',
        LocationAccessStatus.permissionDenied =>
        '위치 권한이 없어 현재 위치를 사용할 수 없어요.',
        LocationAccessStatus.permissionPermanentlyDenied =>
        '앱 설정에서 위치 권한을 허용해주세요.',
        _ => '현재 위치 접근에 실패했어요.',
      };
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    final pos = await _getPosition();
    if (!context.mounted) return;

    final target = (pos != null)
        ? LatLng(pos.latitude, pos.longitude)
        : (fallbackCenter ?? _defaultFallback);

    // 지도만 현재 위치로 이동
    await c.setCenter(target);
    await c.setLevel(zoomLevel);

    // 현재 위치 "오버레이(원형)" 갱신 (마커 X)
    await _drawLocationOverlay(c, target, accuracyMeters: pos?.accuracy);

    messenger.showSnackBar(const SnackBar(content: Text('현재 위치로 이동했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: () => _onPressed(context),
      shape: const CircleBorder(),
      fillColor: Colors.white,
      elevation: 6,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      child: const Icon(Icons.my_location, color: AppColors.mainColor, size: 22),
    );
  }
}
