import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class Room {
  List<Offset> roomVertices;
  String roomName;

  Room(this.roomVertices, this.roomName);
}

class MapDisplayWidget extends StatefulWidget {

  MapDisplayWidget({Key? key}) : super(key: key);

  @override
  State<MapDisplayWidget> createState() => _MapDisplayWidgetState();
}

class _MapDisplayWidgetState extends State<MapDisplayWidget> {
  int xposition = 0;
  int yposition = 0;
  double scale = 1.0;

  int institutionId = 1;
  int buildingId = 1;
  String floorName = "SecondFloor";
  String _name = "";

  String personRoom = "Space";
  String personName = "";

  Map<String, dynamic>? jsonData;
  List<Room> roomsOnFloor = <Room>[];

  @override
  void initState() {
    super.initState();
    buildingOffsetsLoad();
  }

  Future<void> buildingOffsetsLoad() async {
    // Load the JSON file
    String jsonString = await rootBundle.loadString('assets/buildings.json');
    
    // Parse the JSON
    setState(() {
      jsonData = json.decode(jsonString);

      // Find the specific building by institution_id and building_id
      var building = jsonData?['buildings']?.firstWhere((building) =>
          building['insitution_id'] == institutionId &&
          building['building_id'] == buildingId,
          orElse: () => null);

      // If the building exists, access the specified floor data
      if (building != null) {
        var floorData = building[floorName];
        
        // Iterate over each room on the floor and create Room objects
        floorData?.forEach((key, value) {
          List<Offset> points = (value as List).map<Offset>((item) {
            double x = item[0].toDouble();
            double y = item[1].toDouble();
            return Offset(x, y);
          }).toList();

          // Add the room to the list
          roomsOnFloor.add(Room(points, key));
        });
      }
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
    return Container(
          child: Column(children: [
            Row(children: [
              TextButton(onPressed: this.moveLeft, child: const Text("<")),
              TextButton(onPressed: this.moveRight, child: const Text(">")),
              TextButton(onPressed: this.moveUp, child: const Text("^")),
              TextButton(onPressed: this.moveDown, child: const Text("v")),
              TextButton(onPressed: this.zoomIn, child: const Text("+")),
              TextButton(onPressed: this.zoomOut, child: const Text("-")),
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
        );
  }
}

class PointsPainter extends CustomPainter {
  final int xposition;
  final int yposition;
  final double scale;
  final List<Room> roomsOnFloor;
  String finalTextDisplayed = "";
  double sumdX = 0;
  double sumdY = 0;
  double avgdY = 0;
  double avgdX = 0;
  double translatedTextX = 0;
  double translatedTextY = 0;

  PointsPainter(
      this.xposition, this.yposition, this.scale, this.roomsOnFloor);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final textStyle = TextStyle(
      color: const Color.fromARGB(255, 0, 154, 82),
      fontSize: scale*14,
    );

    final pointPaint = Paint()
      ..strokeWidth = 10.0
      ..color = const Color.fromARGB(255, 0, 154, 82)
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..strokeWidth = 2.0
      ..color = const Color.fromARGB(255, 0, 154, 82)
      ..strokeCap = StrokeCap.round;

    for (Room room in roomsOnFloor) {
      String currentRoomName = room.roomName;
    
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

      TextSpan textSpan = TextSpan(
      text: currentRoomName,
      style: textStyle,
      );

      TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      );

      textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
      );

      sumdX = 0;
      sumdY = 0;
      for(Offset point in pointsTransformed)
      {
        sumdX += point.dx;
        sumdY += point.dy;
      }
      avgdY = sumdY/pointsTransformed.length;
      avgdX = sumdX/pointsTransformed.length;

      //translatedTextX = avgdX*0.95;
      //translatedTextY = avgdY*0.95;
      //textPainter.paint(canvas, Offset(avgdX,avgdY));
      textPainter.paint(canvas, Offset(avgdX - textPainter.width / 2, avgdY - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant PointsPainter oldDelegate) {
    return oldDelegate.xposition != xposition ||
        oldDelegate.yposition != yposition ||
        oldDelegate.scale != scale ||
        oldDelegate.roomsOnFloor != roomsOnFloor ||
        oldDelegate.avgdX != avgdX ||
        oldDelegate.avgdY != avgdY ;
  }
}
