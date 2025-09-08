import 'package:flutter/material.dart';
import 'package:joljak/widgets/whitebox.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                Text('profile screen'),
                Whitebox(
                  child: Column(
                    children: [
                      Text("Profile"),
                    ],
                  ),
                )
              ],
            ),
          )
      ),
    );;
  }
}
