import 'package:flutter/material.dart';
import 'package:joljak/widgets/map_widgets/current_location_btn.dart';
import 'package:joljak/widgets/map_widgets/menu_pill.dart';
import 'package:joljak/widgets/map_widgets/search_box.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../widgets/map_widgets/kakao_map_view.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/bottom_sheet.dart';

// 사진 EXIF → 마커 유틸 (카메라 이동 함수 없음)
import 'package:joljak/utils/photo_markers.dart';

class MapScreen extends StatefulWidget {
  /// 앱 진입 직후 자동으로 지도에 마커를 찍고 싶다면 로컬 사진 경로들을 넣어주세요.
  /// 예) ['file:///storage/.../IMG_0001.jpg', '/storage/emulated/0/DCIM/Camera/IMG_0002.jpg']
  final List<String>? initialLocalPhotoPaths;

  const MapScreen({super.key, this.initialLocalPhotoPaths});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  KakaoMapController? _mapController;
  bool _busy = false;
  bool _initialPlotted = false; // 초기 자동 플롯 1회만 수행

  /// 로컬 사진 경로들에서 EXIF 좌표를 읽어 마커 추가
  Future<void> _plotFromLocalPhotoPaths(List<String> localPhotoPaths) async {
    final map = _mapController;
    if (map == null) return;

    setState(() => _busy = true);
    try {
      final points = await readGpsFromLocalPhotos(localPhotoPaths); // EXIF 읽기
      if (points.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진에서 위치 정보를 찾지 못했습니다.')),
        );
        return;
      }

      final markers = buildMarkersFromPhotoPoints(points); // 마커 만들기
      await addPhotoMarkersToMap(map, markers);            // 지도에 추가
      // 요구사항: 카메라 이동 없음
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _autoPlotInitial() async {
    if (_initialPlotted) return;
    final paths = widget.initialLocalPhotoPaths;
    if (paths == null || paths.isEmpty) return;

    _initialPlotted = true;
    await _plotFromLocalPhotoPaths(paths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 지도
            Positioned.fill(
              child: KakaoMapView(
                centerToCurrentOnInit: true, // 지도는 즉시 뜨고, 위치 이동은 백그라운드로
                onMapCreated: (c) async {
                  setState(() => _mapController = c);
                  await _autoPlotInitial(); // ✅ 지도 준비되면 초기 마커 자동 표시
                },
              ),
            ),

            // 🔍 검색창 + 📍 현재위치 버튼
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: SizedBox(height: 48, child: SearchBox()),
                  ),
                  const SizedBox(width: 12),
                  CurrentLocationBtn(mapController: _mapController),
                ],
              ),
            ),

            // 바텀시트 (원하면 레코드 탭 시 수동 플롯도 병행 가능)
            Positioned.fill(
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.09,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return MyBottomSheet(
                    scrollController: scrollController,
                    // onShowRecordPhotos: (paths) => _plotFromLocalPhotoPaths(paths),
                  );
                },
              ),
            ),

            // 오른쪽 하단 메뉴
            const Positioned(
              bottom: 20,
              right: 20,
              child: MenuPill(),
            ),

            // 진행 인디케이터(옵션)
            if (_busy)
              const Positioned(
                right: 16,
                top: 16,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
