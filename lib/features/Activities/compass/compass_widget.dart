import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// A standalone Compass widget that listens for compass updates and rotates its icon
/// based on the target bearing provided.
class CompassWidget extends StatefulWidget {
  final double bearing;
  const CompassWidget({super.key, required this.bearing});

  @override
  CompassWidgetState createState() => CompassWidgetState();
}

class CompassWidgetState extends State<CompassWidget> {
  double _heading = 0;

  @override
  void initState() {
    super.initState();
    FlutterCompass.events?.listen((event) {
      setState(() {
        _heading = event.heading ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the difference between the target bearing and the device's heading.
    double direction = (widget.bearing - _heading) % 360;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Transform.rotate(
        angle: -direction * (pi / 180), // Convert degrees to radians.
        child: const Icon(Icons.navigation, size: 30, color: Colors.red),
      ),
    );
  }
}
