// lib/providers/ar_gallery_provider.dart
//
// 갤러리에서 사진 여러 장 고르기용 Provider
// - 권한: 전체 허용 + 부분 허용(Selected/Limited) 모두 지원
// - 최신 photo_manager API 사용 (getPermissionState / requestPermissionExtend with requestOption)
// - 최근 이미지 일부(기본 300장)만 로드해서 성능/메모리 절약
//
// pubspec:
//   photo_manager: ^3.7.1   // 권장
//
// AndroidManifest 권한 예시:
//   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
//   <!-- API 32 이하도 지원하려면 -->
//   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
//   <!-- EXIF GPS까지 필요하면 -->
//   <!-- <uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION"/> -->
//
// iOS Info.plist:
//   <key>NSPhotoLibraryUsageDescription</key>
//   <string>지도에 사진을 띄우기 위해 사진 접근 권한이 필요합니다.</string>

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class ArGalleryProvider extends ChangeNotifier {
  ArGalleryProvider({this.maxPick = 10});

  /// 한 번에 선택 가능한 최대 장수
  final int maxPick;

  bool _loading = true;
  String? _error;

  List<AssetEntity> _assets = [];
  final Set<String> _selectedIds = {};

  bool get loading => _loading;
  String? get error => _error;
  List<AssetEntity> get assets => _assets;
  int get selectedCount => _selectedIds.length;
  bool isSelected(AssetEntity e) => _selectedIds.contains(e.id);

  /// 초기화: 권한 체크/요청 → 최근 이미지 로드
  Future<void> initialize() async {
    _loading = true;
    _error = null;
    notifyListeners();

    // ✅ 권한 옵션: "이미지"만, EXIF-GPS까지 필요하면 mediaLocation=true
    const reqOpt = PermissionRequestOption(
      iosAccessLevel: IosAccessLevel.readWrite,
      androidPermission: AndroidPermission(
        type: RequestType.image,
        mediaLocation: false, // EXIF GPS가 꼭 필요하면 true로 바꾸고 매니페스트 권한 추가
      ),
    );

    // 현재 권한 상태 확인 (전체/부분 허용 모두 통과)
    PermissionState state =
    await PhotoManager.getPermissionState(requestOption: reqOpt);

    if (!(state.isAuth || state.hasAccess)) {
      // 아직 접근 불가 → 요청
      state = await PhotoManager.requestPermissionExtend(requestOption: reqOpt);
    }

    if (!(state.isAuth || state.hasAccess)) {
      // 여전히 불가 → 에러 메시지 표시
      _error = '사진 접근 권한이 필요합니다. 설정에서 허용해주세요.';
      _loading = false;
      notifyListeners();
      return;
    }

    // 권한 OK(전체/부분 허용) → 로드
    await _loadRecentImages();
    _loading = false;
    notifyListeners();
  }

  /// 최근 이미지 일부 로드 (최신순 300장)
  Future<void> _loadRecentImages() async {
    try {
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            )
          ],
        ),
      );
      if (paths.isEmpty) {
        _assets = [];
        return;
      }
      _assets = await paths.first.getAssetListRange(start: 0, end: 300);
    } catch (e) {
      _error = '갤러리를 불러오는 중 오류가 발생했습니다: $e';
    }
  }

  /// (iOS 한정) 부분 허용에서 추가로 사진 공개하는 시스템 UI
  Future<void> presentLimitedPicker() async {
    if (Platform.isIOS) {
      await PhotoManager.presentLimited();
      await _loadRecentImages();
      notifyListeners();
    } else {
      // Android는 설정 화면으로 유도
      await PhotoManager.openSetting();
    }
  }

  /// 선택 토글
  void toggle(AssetEntity e) {
    if (_selectedIds.contains(e.id)) {
      _selectedIds.remove(e.id);
    } else {
      if (_selectedIds.length >= maxPick) return;
      _selectedIds.add(e.id);
    }
    notifyListeners();
  }

  /// 선택한 항목들 실제 파일로 반환
  Future<List<File>> confirm() async {
    final picks = _assets.where((e) => _selectedIds.contains(e.id));
    final files = <File>[];
    for (final e in picks) {
      final f = await e.file;
      if (f != null) files.add(f);
    }
    return files;
  }

  /// 선택 초기화
  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// 수동 새로고침(권한 변경/앨범 변경 반영)
  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    await _loadRecentImages();
    _loading = false;
    notifyListeners();
  }
}
