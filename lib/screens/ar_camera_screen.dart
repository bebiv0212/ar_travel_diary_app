import 'package:flutter/material.dart';

class ArCameraScreen extends StatelessWidget {
  const ArCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text('ar camera screen')
              ],
            ),
          )
      ),
    );
  }
}
