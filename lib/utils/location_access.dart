import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum LocationAccessStatus {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied, denied,
}

class LocationAccess {
  LocationAccess._();

  /// 기기 위치 서비스가 꺼져 있으면 팝업 → 시스템 설정 열기 → 복귀 후 재확인
  static Future<bool> ensureServiceEnabled(BuildContext context) async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) {
      return true;
    }

    // ⚠️ await 뒤에 context 사용 → 반드시 mounted 가드
    if (!context.mounted) {
      return false;
    }

    final bool? go = await _confirm(
      context,
      title: '위치 서비스가 꺼져 있어요',
      message: '현재 위치 기능을 사용하려면 기기의 위치 서비스를 켜주세요.',
      okLabel: '설정 열기',
    );

    if (go == true) {
      await Geolocator.openLocationSettings();
      // 돌아온 뒤 재확인 (context 사용하지 않음)
      enabled = await Geolocator.isLocationServiceEnabled();
    }

    return enabled;
  }

  /// 권한 확인/요청. 영구 거부면 앱 설정으로 유도 → 복귀 후 재확인
  static Future<LocationAccessStatus> ensurePermission(
    BuildContext context,
  ) async {
    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission(); // 버튼 눌렀을 때만 팝업
    }

    if (perm == LocationPermission.deniedForever) {
      // ⚠️ await 뒤에 context 사용 → 반드시 mounted 가드
      if (!context.mounted) {
        return LocationAccessStatus.permissionPermanentlyDenied;
      }

      final bool? go = await _confirm(
        context,
        title: '위치 권한이 필요해요',
        message: '앱 설정에서 위치 권한을 허용해주세요.',
        okLabel: '앱 설정 열기',
      );

      if (go == true) {
        await Geolocator.openAppSettings();
        perm = await Geolocator.checkPermission();
      }
    }

    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      return LocationAccessStatus.granted;
    } else if (perm == LocationPermission.deniedForever) {
      return LocationAccessStatus.permissionPermanentlyDenied;
    } else {
      return LocationAccessStatus.permissionDenied;
    }
  }

  /// 서비스 + 권한 모두 보장
  static Future<LocationAccessStatus> ensureAll(BuildContext context) async {
    final bool serviceOK = await ensureServiceEnabled(context);
    if (!serviceOK) {
      return LocationAccessStatus.serviceDisabled;
    }
    if (!context.mounted) {
      return LocationAccessStatus.permissionDenied;
    }
    // ensurePermission 내부에서도 mounted 가드를 함
    return ensurePermission(context);
  }

  /// 간단 확인용 다이얼로그 (여기서는 await 전 context 사용 → lint 안전)
  static Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = '취소',
    String okLabel = '확인',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(okLabel),
          ),
        ],
      ),
    );
  }
}
