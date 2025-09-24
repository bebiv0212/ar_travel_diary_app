import 'package:flutter/material.dart';

InputDecoration filledDecoration(
    BuildContext context, {
      required String hintText,
      Widget? suffixIcon,
    }) {
  final radius = BorderRadius.circular(10);
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.grey.shade200,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
    ),
    suffixIcon: suffixIcon,
  );
}
