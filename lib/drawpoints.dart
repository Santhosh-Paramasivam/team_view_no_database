import 'package:flutter/material.dart';

class PointsDisplayPage extends StatelessWidget {
  final List<Offset> points = 
  [
    Offset(50, 100),
    Offset(100, 150),
    Offset(150, 200),
    Offset(200, 250),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Display Points'),
      ),
      body: Center(
        child: Container(
          color: const Color.fromARGB(255, 199, 128, 152), // Set a background color for better visibility
          width: double.infinity, // Define a width for the CustomPaint
          height: 400, // Define a height for the CustomPaint
          child: CustomPaint(
            painter: PointsPainter(points),
          ),
        ),
      ),
    );
  }
}

class PointsPainter extends CustomPainter {
  final List<Offset> points;

  PointsPainter(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    print('Canvas size: $size');
    print('Points: $points');

    final paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.0;

    for (Offset point in points) {
      if (point.dx <= size.width && point.dy <= size.height) {
        canvas.drawCircle(point, 5.0, paint); // Draw a small circle at each point
      } else {
        print('Point out of bounds: $point');
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // No need to repaint if the points don't change
  }
}
