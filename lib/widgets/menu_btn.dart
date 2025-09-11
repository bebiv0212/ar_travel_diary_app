import 'package:flutter/material.dart';
import 'package:joljak/theme/app_colors.dart';

class MenuBtn extends StatelessWidget {
  const MenuBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: () => {},
      shape: const CircleBorder(),
      fillColor: Colors.white,
      elevation: 6,
      constraints: const BoxConstraints.tightFor(
        width: 48, // 원하는 지름
        height: 48, // 원하는 지름
      ),
      child: const Icon(
        Icons.menu, //
        color: AppColors.mainColor,
        size: 22,
      ),
    );
  }
}
