// lib/providers/ar_camera_provider.dart
import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ArCameraProvider extends ChangeNotifier with WidgetsBindingObserver {
  // --- Camera ---
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _isRear = true;

  // 플래시 lazy 판별
  bool _hasFlash = true;
  bool _torchOn = false;

  // --- Sensors / Location ---
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<Position>? _posSub;

  double _pitch = 0.0;     // 대략적 기울기(°)
  double _heading = 0.0;   // 0~360, 북=0
  Position? _position;

  // --- Error state ---
  String? _error;

  // --- Dispose guard ---
  bool _disposed = false; // ✅ 추가

  // --- Getters ---
  CameraController? get controller => _controller;
  bool get isReady => _controller != null && _controller!.value.isInitialized;
  bool get hasFlash => _hasFlash;
  bool get torchOn => _torchOn;
  bool get isRear => _isRear;
  double get pitch => _pitch;
  double get heading => _heading;
  Position? get position => _position;
  String? get error => _error;

  // --- Public lifecycle ---
  Future<void> initialize() async {
    if (_disposed) return; // ✅ 가드
    WidgetsBinding.instance.addObserver(this);
    await _ensureLocationPermission();
    await _initLocation();
    if (_disposed) return;
    await _initCompass();
    if (_disposed) return;
    _initAccelerometer();
    if (_disposed) return;
    await _initCamera();
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> disposeAsync() async {
    // ✅ 먼저 플래그 세팅해서 콜백이 와도 무시되게
    _disposed = true;

    try { await _accelSub?.cancel(); } catch (_) {}
    try { await _compassSub?.cancel(); } catch (_) {}
    try { await _posSub?.cancel(); } catch (_) {}
    try { await _controller?.dispose(); } catch (_) {}

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void dispose() {
    // 비동기 정리 시작(플래그는 위에서 true 처리됨)
    // await를 못 하니 fire-and-forget
    // ignore: discarded_futures
    disposeAsync();
    super.dispose();
  }

  // --- App lifecycle hook ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (_controller == null) return;
    if (state == AppLifecycleState.inactive) {
      _disposeCameraOnly();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // --- Permissions ---
  Future<void> _ensureLocationPermission() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  // --- Sensors / Streams ---
  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      if (_disposed) return;
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (_disposed) return;
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      ).listen((p) {
        if (_disposed) return;            // ✅ 가드
        _position = p;
        notifyListeners();
      }, onError: (_) {
        // 무시
      });
    } catch (_) {}
  }

  Future<void> _initCompass() async {
    final stream = FlutterCompass.events;
    if (stream == null) return;
    _compassSub = stream.listen((event) {
      if (_disposed) return;              // ✅ 가드
      final raw = event.heading;
      if (raw == null) return;
      _heading = (raw + 360) % 360;
      notifyListeners();
    }, onError: (_) {});
  }

  void _initAccelerometer() {
    _accelSub = accelerometerEventStream().listen((e) {
      if (_disposed) return;              // ✅ 가드 (크리티컬)
      final ax = e.x.toDouble();
      final ay = e.y.toDouble();
      final az = e.z.toDouble();
      final pitchRad = atan2(ax, sqrt(ay * ay + az * az));
      _pitch = pitchRad * 180 / pi;
      notifyListeners();
    }, onError: (_) {});
  }

  // --- Camera ---
  Future<void> _initCamera() async {
    try {
      if (_disposed) return;
      _error = null;
      _cameras = await availableCameras();
      if (_disposed) return;
      final cam = _selectCamera();
      final ctrl = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (_disposed) {
        // 이미 dispose 되었으면 즉시 정리
        try { await ctrl.dispose(); } catch (_) {}
        return;
      }

      _torchOn = false;
      _controller = ctrl;
      notifyListeners();
    } catch (e) {
      if (_disposed) return;
      _error = '카메라 초기화 실패: $e';
      notifyListeners();
    }
  }

  CameraDescription _selectCamera() {
    if (_cameras.isEmpty) {
      throw StateError('No cameras available');
    }
    final lens = _isRear ? CameraLensDirection.back : CameraLensDirection.front;
    final found = _cameras.where((c) => c.lensDirection == lens);
    return found.isNotEmpty ? found.first : _cameras.first;
  }

  Future<void> _disposeCameraOnly() async {
    try { await _controller?.dispose(); } catch (_) {}
    _controller = null;
  }

  // --- Actions ---
  Future<void> toggleTorch() async {
    final ctrl = _controller;
    if (ctrl == null || _disposed) return;

    try {
      _torchOn = !_torchOn;
      await ctrl.setFlashMode(_torchOn ? FlashMode.torch : FlashMode.off);
      _hasFlash = true;
    } catch (e) {
      _torchOn = false;
      _hasFlash = false;
      _error = '이 기기는 플래시를 지원하지 않거나 사용할 수 없습니다.';
    }
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (_disposed) return;
    _isRear = !_isRear;
    try { await _controller?.setFlashMode(FlashMode.off); } catch (_) {}
    _torchOn = false;
    await _disposeCameraOnly();
    if (_disposed) return;
    await _initCamera();
  }

  Future<XFile?> capture() async {
    if (!isReady || _disposed) return null;
    try {
      final file = await _controller!.takePicture();
      return file;
    } catch (e) {
      if (_disposed) return null;
      _error = '촬영 실패: $e';
      notifyListeners();
      return null;
    }
  }
}
