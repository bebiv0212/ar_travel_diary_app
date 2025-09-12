import 'package:flutter/material.dart';
import 'package:joljak/widgets/bottom_sheet.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
            children: [
              Text('map screen'),
              Expanded(child: Stack(children: [
                Align(
                  alignment: Alignment.bottomCenter,child:
              DraggableScrollableSheet(
                  initialChildSize: 0.5,//기본 크키
                  minChildSize: 0.5,//작은
                  maxChildSize: 0.99,//큰
                  expand: false,
                  builder:(context,scrollController){
                return MyBottomSheet(scrollController:scrollController);
              })
                )]))
            ],
          ),
      ),
    );
  }
}
