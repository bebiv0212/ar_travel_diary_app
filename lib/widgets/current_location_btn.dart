import 'package:flutter/material.dart';
import 'package:joljak/theme/app_colors.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:joljak/utils/location_access.dart';

/// 현재 위치로 지도 중심 이동 + 마커 찍기 버튼
/// - 버튼을 눌렀을 때만 권한/설정 유도
class CurrentLocationBtn extends StatelessWidget {
  final KakaoMapController? mapController;
  final String markerId;
  final int zoomLevel;
  final LatLng? fallbackCenter; // null이면 _defaultFallback 사용

  static final LatLng _defaultFallback = LatLng(37.5665, 126.9780); // 서울시청

  const CurrentLocationBtn({
    super.key,
    required this.mapController,
    this.markerId = 'current_location_marker',
    this.zoomLevel = 3,
    this.fallbackCenter,
  });

  Future<void> _centerAndPin(LatLng latLng) async {
    final c = mapController;
    if (c == null) return;

    await c.setCenter(latLng);
    await c.setLevel(zoomLevel);

    try {
      await c.clearMarker(markerIds: [markerId]); // 버전에 따라 없으면 무시
    } catch (_) {}

    await c.addMarker(
      markers: [
        Marker(markerId: markerId, latLng: latLng, infoWindowContent: '현재 위치'),
      ],
    );
  }

  Future<Position?> _getPosition() async {
    try {
      // ⬇️ 최신 API: LocationSettings 사용 (desiredAccuracy/timeLimit 대체)
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      );
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  Future<void> _onPressed(BuildContext context) async {
    if (mapController == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지도가 아직 준비되지 않았어요.')));
      return;
    }

    // await 전에 Messenger 미리 캐싱 (context across async gap 회피)
    final messenger = ScaffoldMessenger.of(context);

    final status = await LocationAccess.ensureAll(context);
    if (!context.mounted) return;

    if (status != LocationAccessStatus.granted) {
      final msg = switch (status) {
        LocationAccessStatus.serviceDisabled =>
          '위치 서비스가 꺼져 있어 현재 위치를 가져올 수 없어요.',
        LocationAccessStatus.permissionDenied => '위치 권한이 없어 현재 위치를 사용할 수 없어요.',
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

    await _centerAndPin(target);

    if (!context.mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('현재 위치로 이동했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: () => _onPressed(context),
      shape: const CircleBorder(),
      fillColor: Colors.white,
      elevation: 6,
      constraints: const BoxConstraints.tightFor(
        width: 48, // 원하는 지름
        height: 48, // 원하는 지름
      ),
      child: const Icon(
        Icons.my_location,
        color: AppColors.mainColor,
        size: 22,
      ),
    );
  }
}
