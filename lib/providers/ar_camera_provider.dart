// lib/providers/ar_camera_provider.dart
//
// AR 카메라용 Provider:
// - 카메라 라이프사이클 관리
// - 전/후면 전환
// - 플래시 토글(지원 여부는 토글 시도 기반 lazy 판별)
// - 나침반(heading) / 가속도(pitch)
// - 위치 스트림(선택)
//
// 필요 패키지(pubspec):
// camera, flutter_compass(>=0.8.1 권장), sensors_plus, geolocator
//
// iOS 권한(Info.plist) 권장:
// - NSCameraUsageDescription
// - NSLocationWhenInUseUsageDescription
// - NSMotionUsageDescription

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

  // 플래시: camera 플러그인에 "hasFlash" API가 없어 lazy 판별 적용
  bool _hasFlash = true; // 처음엔 보이게, 실패 시 false로
  bool _torchOn = false;

  // --- Sensors / Location ---lib/screens/ar_camera_screen.dart:55:15: Error: No named parameter with the name 'onModelLoaded'.
  //               onModelLoaded: (_) => debugPrint('Model loaded'),
  //               ^^^^^^^^^^^^^
  // ../../AppData/Local/Pub/Cache/hosted/pub.dev/model_viewer_plus-1.9.3/lib/src/model_viewer_plus.dart:35:9: Context: Found this candidate, but the arguments don't match.
  //   const ModelViewer({
  //         ^^^^^^^^^^^
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<Position>? _posSub;

  double _pitch = 0.0;     // 대략적 기울기(°)
  double _heading = 0.0;   // 0~360, 북=0
  Position? _position;

  // --- Error state ---
  String? _error;

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
    WidgetsBinding.instance.addObserver(this);
    await _ensureLocationPermission(); // 위치는 선택(없어도 동작)
    await _initLocation();
    await _initCompass();
    _initAccelerometer();
    await _initCamera();
    notifyListeners();
  }

  Future<void> disposeAsync() async {
    try { await _controller?.dispose(); } catch (_) {}
    try { await _accelSub?.cancel(); } catch (_) {}
    try { await _compassSub?.cancel(); } catch (_) {}
    try { await _posSub?.cancel(); } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void dispose() {
    disposeAsync();
    super.dispose();
  }

  // --- App lifecycle hook ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
        perm = await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  // --- Sensors / Streams ---
  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      ).listen((p) {
        _position = p;
        notifyListeners();
      });
    } catch (_) {}
  }

  Future<void> _initCompass() async {
    final stream = FlutterCompass.events;
    if (stream == null) return;
    _compassSub = stream.listen((event) {
      final raw = event.heading;
      if (raw == null) return;
      _heading = (raw + 360) % 360;
      notifyListeners();
    }, onError: (_) {});
  }

  void _initAccelerometer() {
    _accelSub = accelerometerEventStream().listen((e) {
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
      _error = null;
      _cameras = await availableCameras();
      final cam = _selectCamera();
      final ctrl = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();

      // 플래시는 lazy 판별(토글 시도 시 실패 → false)
      _torchOn = false;
      _controller = ctrl;
      notifyListeners();
    } catch (e) {
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
    if (ctrl == null) return;

    try {
      _torchOn = !_torchOn;
      await ctrl.setFlashMode(_torchOn ? FlashMode.torch : FlashMode.off);
      _hasFlash = true; // 성공 → 지원됨
    } catch (e) {
      // 실패 → 미지원/거부로 간주
      _torchOn = false;
      _hasFlash = false;
      _error = '이 기기는 플래시를 지원하지 않거나 사용할 수 없습니다.';
    }
    notifyListeners();
  }

  Future<void> switchCamera() async {
    _isRear = !_isRear;
    try {
      await _controller?.setFlashMode(FlashMode.off);
    } catch (_) {}
    _torchOn = false;
    await _disposeCameraOnly();
    await _initCamera();
  }

  Future<XFile?> capture() async {
    if (!isReady) return null;
    try {
      final file = await _controller!.takePicture();
      return file;
    } catch (e) {
      _error = '촬영 실패: $e';
      notifyListeners();
      return null;
    }
  }
}
