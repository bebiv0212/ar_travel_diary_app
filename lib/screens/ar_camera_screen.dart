// lib/screens/ar_camera_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:joljak/utils/location_access.dart'; // ✅ 패키지명 기준 import (또는 상대경로: '../utils/location_access.dart')

class ArCameraScreen extends StatefulWidget {
  const ArCameraScreen({super.key});

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isPermissionGranted = false;
  XFile? _capturedImageFile;
  Position? _currentPosition;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _titleController = TextEditingController();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        setState(() {
          _isPermissionGranted = true;
        });

        _cameras = await availableCameras();
        if (_cameras != null && _cameras!.isNotEmpty) {
          _controller = CameraController(_cameras![0], ResolutionPreset.high);
          await _controller!.initialize();
          if (mounted) {
            setState(() {});
          }
        } else {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사용 가능한 카메라가 없습니다.')),
              );
            });
          }
        }
      } else {
        setState(() {
          _isPermissionGranted = false;
        });
      }
    } catch (e) {
      debugPrint('카메라 초기화 오류: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('카메라 초기화 중 오류가 발생했습니다: $e')),
          );
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    // ✅ 위치 접근 보장
    // 위치 접근 보장
    final locationStatus = await LocationAccess.ensureAll(context);

    if (locationStatus != LocationAccessStatus.granted) {
      String msg;
      if (locationStatus == LocationAccessStatus.serviceDisabled) {
        msg = '위치 서비스가 꺼져 있습니다. 설정에서 켜주세요.';
      } else if (locationStatus == LocationAccessStatus.denied) {
        msg = '위치 정보 접근 권한이 필요합니다.';
      } else {
        msg = '위치 권한 오류가 발생했습니다.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    }


    try {
      final image = await _controller!.takePicture();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _capturedImageFile = image;
        _currentPosition = position;
        _titleController.text = '';
      });
    } catch (e) {
      debugPrint('사진 촬영 또는 위치 정보 가져오기 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 촬영 또는 위치 정보 가져오기 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('AR 카메라')),
        body: const Center(
          child: Text('카메라 권한이 필요합니다.'),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('AR 카메라')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 카메라'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          _buildFrameOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFrameOverlay() {
    String locationText = '위치 정보 없음';
    if (_currentPosition != null) {
      locationText =
      '위도: ${_currentPosition!.latitude.toStringAsFixed(4)}, 경도: ${_currentPosition!.longitude.toStringAsFixed(4)}';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _capturedImageFile != null
                ? Image.file(File(_capturedImageFile!.path), fit: BoxFit.cover)
                : const Center(
              child: Text(
                '사진을 촬영해주세요',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          if (_capturedImageFile != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _titleController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: const InputDecoration(
                  hintText: '사진 제목을 입력하세요',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              locationText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }
}
