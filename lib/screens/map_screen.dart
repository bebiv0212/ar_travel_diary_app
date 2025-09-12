import 'package:flutter/material.dart';
import 'package:joljak/widgets/current_location_btn.dart';
import 'package:joljak/widgets/menu_container.dart';
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
                centerToCurrentOnInit: true, // 지도는 즉시 뜨고, 위치 이동은 백그라운드로
                onMapCreated: (c) => setState(() => _mapController = c),
              ),
            ),

            // 🔍 검색창 + 📍 현재위치 버튼 (상단에 함께 배치)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  // 검색창이 가로를 대부분 차지
                  const Expanded(child: SearchBox()),
                  // 현재위치 버튼 (FAB 그대로 사용)
                  CurrentLocationBtn(mapController: _mapController),
                ],
              ),
            ),

            Positioned(
              bottom: 20, //
              right: 20,
              child: MenuContainer(),
            ),
          ],
        ),
      ),
    );
  }
}
