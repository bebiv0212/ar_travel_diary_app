import 'package:flutter/material.dart';
import 'package:joljak/widgets/current_location_btn.dart';
import 'package:joljak/widgets/search_box.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../widgets/kakao_map_view.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  KakaoMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 지도
            Positioned.fill(
              child: KakaoMapView(
                onMapCreated: (controller) async {
                  debugPrint('여기에요여기 : $controller');
                  setState(() {
                    _mapController = controller; // ✅ 버튼에 전달될 컨트롤러 갱신
                  });
                  await controller.setCenter(LatLng(37.5665, 126.9780)); // const 제거
                  await controller.setLevel(3);
                },
              ),
            ),

            // 🔍 검색창 + 📍 현재위치 버튼 (상단에 함께 배치)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 검색창이 가로를 대부분 차지
                  const Expanded(child: SearchBox()),
                  const SizedBox(width: 12),
                  // 현재위치 버튼 (FAB 그대로 사용)
                  CurrentLocationBtn(mapController: _mapController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
