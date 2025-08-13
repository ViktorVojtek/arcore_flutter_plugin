import 'package:flutter/material.dart';
import 'manual_gesture_example.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manual Gesture Control Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ManualGestureExample(),
      debugShowCheckedModeBanner: false,
    );
  }
}
