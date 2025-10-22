import 'dart:async';
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

  /// WebView(KakaoMap) 자체를 첫 프레임 뒤에 살짝 지연 마운트해서 초기 jank 완화
  final int mountDelayMs;

  /// 현재 위치 원(circle) ID들 — 다른 곳과 충돌 없게 고정
  static const String kDotCircleId = 'my_loc_dot';
  static const String kAccCircleId = 'my_loc_acc';

  const KakaoMapView({
    super.key,
    this.onMapCreated,
    this.centerToCurrentOnInit = false,
    this.fallbackCenter,
    this.initialLevel = 3,
    this.deferLocationMs = 200,
    this.locationTimeoutMs = 2000,
    this.preferLastKnownFirst = true,
    this.mountDelayMs = 120, // 🔹 추가: 기본 120ms 뒤에 WebView 마운트
  });

  @override
  State<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  KakaoMapController? _c;
  bool _showMap = false;
  Timer? _mountTimer;

  // 오버레이 연속 갱신 억제용(디바운스)
  Timer? _overlayDebounce;

  @override
  void initState() {
    super.initState();
    // 첫 프레임 이후 살짝 지연해서 KakaoMap(WebView) 마운트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final delay = Duration(milliseconds: widget.mountDelayMs.clamp(0, 1000));
      _mountTimer = Timer(delay, () {
        if (mounted) setState(() => _showMap = true);
      });
    });
  }

  @override
  void dispose() {
    _mountTimer?.cancel();
    _overlayDebounce?.cancel();
    // kakao_map_plugin은 명시 dispose가 없어서 컨트롤러만 끊어둡니다.
    _c = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showMap) {
      // 초기 jank 줄이기 위해 잠깐 placeholder
      return const SizedBox.expand(child: ColoredBox(color: Colors.transparent));
    }

    return KakaoMap(
      center: widget.fallbackCenter ?? LatLng(37.5665, 126.9780),
      onMapCreated: (controller) async {
        _c = controller;
        widget.onMapCreated?.call(controller);

        await controller.setLevel(widget.initialLevel);

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

  Future<void> _drawLocationOverlay(
      KakaoMapController c,
      LatLng center, {
        double? accuracyMeters,
      }) async {
    // 연속 호출 시 16ms 내 중복 작업 방지(디바운스)
    _overlayDebounce?.cancel();
    _overlayDebounce = Timer(const Duration(milliseconds: 16), () async {
      try {
        await c.clearCircle(
          circleIds: [KakaoMapView.kDotCircleId, KakaoMapView.kAccCircleId],
        );
      } catch (_) {}

      // 현재 위치 점(6m 반경 원) — 지상 단위(m)
      final dot = Circle(
        circleId: KakaoMapView.kDotCircleId,
        center: center,
        radius: 6,
        strokeColor: Colors.white,
        strokeOpacity: 1,
        strokeWidth: 2,
        fillColor: const Color(0xFF1976D2),
        fillOpacity: 1,
        zIndex: 10000,
      );

      final List<Circle> circles = [dot];

      // 정확도 반경
      if (accuracyMeters != null &&
          accuracyMeters.isFinite &&
          accuracyMeters > 0) {
        final clamped = accuracyMeters.clamp(10, 300.0);
        circles.add(
          Circle(
            circleId: KakaoMapView.kAccCircleId,
            center: center,
            radius: clamped.toDouble(),
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
    });
  }

  // 지도는 이미 뜬 뒤, 비차단으로 현재 위치 표시/이동
  Future<void> _centerToCurrentNonBlocking() async {
    final c = _c;
    if (c == null) return;

    LatLng? quickTarget;

    // 1) lastKnown으로 "빠른" 점/센터
    if (widget.preferLastKnownFirst) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          quickTarget = LatLng(last.latitude, last.longitude);
          // 오버레이 먼저 찍고(비차단)
          // ignore: unawaited_futures
          _drawLocationOverlay(c, quickTarget);

          // 지도 비차단 이동
          // ignore: unawaited_futures
          c.setCenter(quickTarget);
          // ignore: unawaited_futures
          c.setLevel(widget.initialLevel);
        }
      } catch (_) {}
    }

    // 2) 서비스/권한 체크 & 정확 위치
    try {
      final service = await Geolocator.isLocationServiceEnabled();
      if (!service) {
        if (quickTarget == null) {
          final fb = widget.fallbackCenter ?? LatLng(37.5665, 126.9780);
          // ignore: unawaited_futures
          _drawLocationOverlay(c, fb);
        }
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        // 자동 진행 원치 않으면 주석 처리
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (quickTarget == null) {
          final fb = widget.fallbackCenter ?? LatLng(37.5665, 126.9780);
          // ignore: unawaited_futures
          _drawLocationOverlay(c, fb);
        }
        return;
      }

      // 현재 위치(시간 제한을 실제 호출에 직접 적용)
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(milliseconds: widget.locationTimeoutMs), // 🔹 핵심
        );
      } catch (_) {
        // current 실패: lastKnown/폴백만 유지
        return;
      }

      final precise = LatLng(pos.latitude, pos.longitude);

      // 오버레이 갱신 (정확도 반경 포함)
      // ignore: unawaited_futures
      _drawLocationOverlay(c, precise, accuracyMeters: pos.accuracy);

      // 지도 이동
      // ignore: unawaited_futures
      c.setCenter(precise);
      // ignore: unawaited_futures
      c.setLevel(widget.initialLevel);
    } catch (_) {
      if (quickTarget == null) {
        final fb = widget.fallbackCenter ?? LatLng(37.5665, 126.9780);
        // ignore: unawaited_futures
        _drawLocationOverlay(c, fb);
      }
    }
  }
}
