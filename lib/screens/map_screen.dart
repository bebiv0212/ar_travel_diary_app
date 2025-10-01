import 'package:flutter/material.dart';
import 'package:joljak/widgets/map_widgets/current_location_btn.dart';
import 'package:joljak/widgets/map_widgets/menu_pill.dart';
import 'package:joljak/widgets/map_widgets/search_box.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../widgets/map_widgets/kakao_map_view.dart';
import 'package:joljak/widgets/bottom_sheet_widgets/bottom_sheet.dart';

// 사진 EXIF → 마커 유틸
import 'package:joljak/utils/photo_markers.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  KakaoMapController? _mapController;
  bool _busy = false;

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
      // 카메라 이동 없음
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                onMapCreated: (c) => setState(() => _mapController = c),
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

            // 바텀시트 (레코드 탭 시 수동 플롯도 가능)
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

            // 오른쪽 하단 메뉴 (촬영/업로드 직후 지도에 바로 마커)
            Positioned(
              bottom: 20,
              right: 20,
              child: MenuPill(
                onPhotosReady: (paths) => _plotFromLocalPhotoPaths(paths),
              ),
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
