import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';

class KakaoMapView extends StatefulWidget {
  final Function(KakaoMapController)? onMapCreated;

  /// 지도가 준비되면 현재 위치로 자동 이동할지 (기본: 꺼짐)
  final bool centerToCurrentOnInit;

  /// 초기 표시/실패 폴백 센터 (기본: 서울시청)
  final LatLng? fallbackCenter;

  /// 줌 레벨 (작을수록 확대)
  final int initialLevel;

  /// 위치 이동을 첫 프레임 이후로 지연(ms) → 초기 렌더 방해 X
  final int deferLocationMs;

  /// getCurrentPosition 타임아웃(ms)
  final int locationTimeoutMs;

  /// lastKnown 먼저 시도 후, 정확 위치로 재이동할지
  final bool preferLastKnownFirst;

  const KakaoMapView({
    super.key,
    this.onMapCreated,
    this.centerToCurrentOnInit = false,
    this.fallbackCenter,
    this.initialLevel = 3,
    this.deferLocationMs = 200,
    this.locationTimeoutMs = 2000,
    this.preferLastKnownFirst = true,
  });

  @override
  State<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  KakaoMapController? _c;

  @override
  Widget build(BuildContext context) {
    return KakaoMap(
      center: widget.fallbackCenter ?? LatLng(37.5665, 126.9780),
      onMapCreated: (controller) async {
        _c = controller;
        widget.onMapCreated?.call(controller);

        // 초기 줌만 세팅 (빠른 첫 렌더)
        await controller.setLevel(widget.initialLevel);

        // 위치 이동은 비차단으로 예약 실행
        if (widget.centerToCurrentOnInit) {
          _scheduleCenterToCurrent();
        }
      },
    );
  }

  void _scheduleCenterToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.deferLocationMs > 0) {
        await Future.delayed(Duration(milliseconds: widget.deferLocationMs));
      }
      if (!mounted) return;
      _centerToCurrentNonBlocking();
    });
  }

  // 지도는 이미 뜬 뒤, 백그라운드로 현재 위치 이동 (await 결과에 의존 X)
  Future<void> _centerToCurrentNonBlocking() async {
    final c = _c;
    if (c == null) return;

    LatLng? quickTarget;

    // 1) lastKnown으로 즉시 이동(있으면)
    if (widget.preferLastKnownFirst) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          quickTarget = LatLng(last.latitude, last.longitude);
          // 비차단 이동
          // ignore: unawaited_futures
          c.setCenter(quickTarget);
          // ignore: unawaited_futures
          c.setLevel(widget.initialLevel);
        }
      } catch (_) {}
    }

    // 2) 서비스/권한 체크 → 현재 위치 (짧은 타임아웃, 최신 API)
    try {
      final service = await Geolocator.isLocationServiceEnabled();
      if (!service) {
        if (quickTarget == null) {
          // 폴백만 이동
          // ignore: unawaited_futures
          c.setCenter(widget.fallbackCenter ?? LatLng(37.5665, 126.9780));
          // ignore: unawaited_futures
          c.setLevel(widget.initialLevel);
        }
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        // 자동 이동에서 권한을 바로 띄우고 싶지 않다면 이 줄을 제거하세요.
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (quickTarget == null) {
          // 폴백
          // ignore: unawaited_futures
          c.setCenter(widget.fallbackCenter ?? LatLng(37.5665, 126.9780));
          // ignore: unawaited_futures
          c.setLevel(widget.initialLevel);
        }
        return;
      }

      // 현재 위치 (LocationSettings 사용)
      final settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(milliseconds: widget.locationTimeoutMs),
      );

      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(locationSettings: settings);
      } catch (_) {
        // current 실패 시 lastKnown가 이미 반영되어 있으면 그대로 둠
        return;
      }

      final precise = LatLng(pos.latitude, pos.longitude);
      // 최신 좌표로 다시 이동 (비차단)
      // ignore: unawaited_futures
      c.setCenter(precise);
      // ignore: unawaited_futures
      c.setLevel(widget.initialLevel);
    } catch (_) {
      if (quickTarget == null) {
        // fallback
        // ignore: unawaited_futures
        c.setCenter(widget.fallbackCenter ?? LatLng(37.5665, 126.9780));
        // ignore: unawaited_futures
        c.setLevel(widget.initialLevel);
      }
    }
  }
}
