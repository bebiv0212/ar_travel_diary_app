import 'package:flutter/material.dart';

class Greybox extends StatelessWidget {
  final Icon icon;
  final Text textInt;
  final String textStr;
  final TextStyle? textStrStyle;
  final Widget? subtitle;

  const Greybox({
    super.key,
    required this.icon,
    required this.textInt,
    required this.textStr,
    this.textStrStyle,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      height: 160,
      decoration: BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            icon,
            SizedBox(
              height: subtitle == null ? null : 61, //
              // 👈 subtitle 없으면 높이 제한 없음
              child: Column(
                mainAxisSize: MainAxisSize.min, // 👈 내용만큼만 차지
                children: [
                  textInt,
                  if (subtitle != null) ...[subtitle!],
                ],
              ),
            ),
            Text(textStr, style: textStrStyle),
          ],
        ),
      ),
    );
  }
}
