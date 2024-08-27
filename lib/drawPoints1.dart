import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class Room {
  List<Offset> roomVertices;
  String roomName;

  Room(this.roomVertices, this.roomName);
}

class PointsDisplayPage extends StatefulWidget {
  const PointsDisplayPage({super.key});

  @override
  State<PointsDisplayPage> createState() => _PointsDisplayPageState();
}

class _PointsDisplayPageState extends State<PointsDisplayPage> {
  int xposition = 0;
  int yposition = 0;
  double scale = 1.0;

  Map<String, dynamic>? jsonData;
  List<Room> roomsOnFloor = <Room>[];

  @override
  void initState() {
    super.initState();
    loadJson();
  }

  Future<void> loadJson() async {
    String jsonString = await rootBundle.loadString('assets/Building1.json');
    setState(() {
      jsonData = json.decode(jsonString);
      var floor = jsonData?['GroundFloor'];
      floor?.forEach((key, value) {
        List<Offset> points = value.map<Offset>((item) {
          double x = item[0].toDouble();
          double y = item[1].toDouble();
          return Offset(x, y);
        }).toList();

        roomsOnFloor.add(Room(points, key));
      });
    });
  }

  void moveRight() {
    setState(() {
      xposition += 8;
    });
  }

  void moveUp() {
    setState(() {
      yposition -= 8;
    });
  }

  void moveDown() {
    setState(() {
      yposition += 8;
    });
  }

  void moveLeft() {
    setState(() {
      xposition -= 8;
    });
  }

  void zoomIn() {
    setState(() {
      scale += 0.1;
    });
  }

  void zoomOut() {
    setState(() {
      scale -= 0.1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Santhosh Points")),
        body: Container(
          width: 500,
          height: 500,
          child: Column(children: [
            Row(children: [
              TextButton(onPressed: this.moveLeft, child: Text("<")),
              TextButton(onPressed: this.moveRight, child: Text(">")),
              TextButton(onPressed: this.moveUp, child: Text("^")),
              TextButton(onPressed: this.moveDown, child: Text("v")),
              TextButton(onPressed: this.zoomIn, child: Text("+")),
              TextButton(onPressed: this.zoomOut, child: Text("-")),
            ]),
            Container(
                width: 500,
                height: 400,
                color: const Color.fromARGB(255, 255, 255, 255),
                child: CustomPaint(
                  painter: PointsPainter(
                      xposition, yposition, scale, roomsOnFloor),
                ))
          ]),
        ));
  }
}

class PointsPainter extends CustomPainter {
  final int xposition;
  final int yposition;
  final double scale;
  final List<Room> roomsOnFloor;
  double sumdX = 0;
  double sumdY = 0;

  PointsPainter(
      this.xposition, this.yposition, this.scale, this.roomsOnFloor);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final pointPaint = Paint()
      ..strokeWidth = 10.0
      ..color = const Color.fromARGB(255, 0, 154, 82)
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..strokeWidth = 2.0
      ..color = const Color.fromARGB(255, 0, 154, 82)
      ..strokeCap = StrokeCap.round;

    for (Room room in roomsOnFloor) {
      List<Offset> pointsTransformed = room.roomVertices.map((point) {
        return Offset(
            scale * (point.dx - xposition), scale * (point.dy - yposition));
      }).toList();

      for (int i = 0; i < pointsTransformed.length; i++) {
        Offset start = pointsTransformed[i];
        Offset end = pointsTransformed[(i + 1) % pointsTransformed.length];
        canvas.drawLine(start, end, linePaint);
        canvas.drawCircle(start, 4, pointPaint);
      }

      sumdX = 0;
      sumdY = 0;
      for(Offset point in pointsTransformed)
      {
        sumdX += point.dx;
        sumdY += point.dy;
      }
    }
  }

  @override
  bool shouldRepaint(covariant PointsPainter oldDelegate) {
    return oldDelegate.xposition != xposition ||
        oldDelegate.yposition != yposition ||
        oldDelegate.scale != scale ||
        oldDelegate.roomsOnFloor != roomsOnFloor;
  }
}
