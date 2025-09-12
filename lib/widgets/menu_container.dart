import 'package:flutter/material.dart';
import 'package:joljak/widgets/whitebox.dart';

class MenuContainer extends StatelessWidget {
  const MenuContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Whitebox(
      child: Column(
        children: [
          GestureDetector(
            child: Container(child: Column(children: [Text('')])),
          ),
        ],
      ),
    );
  }
}
