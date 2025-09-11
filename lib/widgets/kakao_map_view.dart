import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class KakaoMapView extends StatefulWidget {
  final Function(KakaoMapController)? onMapCreated;

  const KakaoMapView({super.key, this.onMapCreated});

  @override
  State<KakaoMapView> createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  @override
  Widget build(BuildContext context) {
    return KakaoMap(
      center: LatLng(37.5665, 126.9780),
      onMapCreated: widget.onMapCreated, // ✅ 반드시 widget.onMapCreated로 전달
    );
  }
}
