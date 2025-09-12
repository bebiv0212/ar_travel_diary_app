import 'package:flutter/material.dart';

class Greybox extends StatelessWidget {
  final Icon icon;
  final Text text_int;
  final String text_str;
  final TextStyle? textStrStyle;
  final Widget? subtitle;

  const Greybox({
    super.key,
    required this.icon,
    required this.text_int,
    required this.text_str,
    this.textStrStyle,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            icon,
            SizedBox(
              height: subtitle == null ? null : 61,
              // 👈 subtitle 없으면 높이 제한 없음
              child: Column(
                mainAxisSize: MainAxisSize.min, // 👈 내용만큼만 차지
                children: [
                  text_int,
                  if (subtitle != null) ...[subtitle!],
                ],
              ),
            ),
            Text(text_str, style: textStrStyle),
          ],
        ),
      ),
    );
  }
}
