import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_colors.dart';

class CurrentLocationBtn extends StatelessWidget {
  final KakaoMapController? mapController;
  final String markerId;

  const CurrentLocationBtn({
    super.key,
    required this.mapController,
    this.markerId = 'current_location_marker',
  });

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _ensureControllerReady() async {
    // 컨트롤러가 null이 아니고, 간단한 호출이 성공하면 "준비됨"으로 간주
    final c = mapController;
    if (c == null) return false;
    try {
      // getLevel 같은 가벼운 호출로 준비상태 확인
      final _ = await c.getLevel();
      return true;
    } catch (_) {
      // onMapCreated 직후 바로는 준비가 덜 된 경우가 있어 약간 대기 후 재시도
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        final _ = await c.getLevel();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<Position?> _getPositionWithFallback() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  Future<void> _centerAndPin(LatLng latLng) async {
    final c = mapController;
    if (c == null) return;

    // 1) 지도 이동/확대
    await c.setCenter(latLng);
    await c.setLevel(3); // 숫자 작을수록 확대

    // 2) 기존 동일 ID 마커 제거 (지원 메서드: clearMarker)
    try {
      await c.clearMarker(markerIds: [markerId]);
    } catch (_) {
      // 구버전이면 무시하거나 c.clear()로 전체 삭제 가능
      // await c.clear();
    }

    // 3) 마커 추가 (리스트 형태로 넘겨야 함)
    await c.addMarker(
      markers: [
        Marker(
          markerId: markerId,
          latLng: latLng,
          infoWindowContent: '현재 위치',
        ),
      ],
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    // A. 컨트롤러 준비 확인
    final ready = await _ensureControllerReady();
    if (!ready) {
      _snack(context, '지도가 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요.');
      return;
    }

    // B. 위치 획득
    final pos = await _getPositionWithFallback();
    if (pos == null) {
      _snack(context, '현재 위치를 가져올 수 없어요. (에뮬레이터 Location ON + 좌표 Set Location 필요)');
      // 안전 기본값(서울시청)으로 이동 + 핀
      await _centerAndPin(LatLng(37.5665, 126.9780));
      return;
    }

    // C. 지도 이동 + 핀
    await _centerAndPin(LatLng(pos.latitude, pos.longitude));
    _snack(context, '현재 위치로 이동했습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: () => _onPressed(context),
      shape: const CircleBorder(),
      fillColor: Colors.white,
      elevation: 6,
      constraints: const BoxConstraints.tightFor(
        width: 48,  // 원하는 지름
        height: 48, // 원하는 지름
      ),
      child: const Icon(Icons.my_location, color: AppColors.mainColor, size: 22),
    );
  }
}
