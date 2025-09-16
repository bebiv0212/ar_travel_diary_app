import 'package:flutter/material.dart';

class Whitebox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const Whitebox({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20)
      ),
      child: child
    );
  }
}
