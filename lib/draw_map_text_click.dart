// ignore: unnecessary_import
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'custom_datatypes/member.dart';

class RoomEventDetails {
  String roomName;
  String eventName;

  RoomEventDetails(this.roomName, this.eventName);
}

class Room {
  List<Offset> roomVertices;
  String roomName;
  late Offset roomCenter;

  Room(this.roomVertices, this.roomName) {
    double sumdX = 0;
    double sumdY = 0;
    for (Offset roomVertex in roomVertices) {
      sumdX += roomVertex.dx;
      sumdY += roomVertex.dy;
    }

    this.roomCenter =
        Offset(sumdX / roomVertices.length, sumdY / roomVertices.length);
  }
}

class MapDetailsDisplayWidget extends StatefulWidget {
  const MapDetailsDisplayWidget({super.key});

  @override
  State<MapDetailsDisplayWidget> createState() =>
      MapDetailsDisplayWidgetState();
}

class MapDetailsDisplayWidgetState extends State<MapDetailsDisplayWidget> {
  late int xposition;
  late int yposition;
  late double scale;

  late Member memberSearched;

  late int buildingId;
  late String floorName;
  late String buildingName;

  late String personName;

  late int appUserInstitutionID;

  Map<String, dynamic>? jsonData;
  List<Room> roomsOnFloor = <Room>[];
  List<RoomEventDetails> roomDetails = <RoomEventDetails>[];
  List<Offset> buildingBoundaries = <Offset>[];
  late Offset centering = const Offset(0, 0);
  late Offset previousOffset;
  late double initialScale; // To keep track of the previous drag position
  late Size drawingWindowSize;

  late Path path;
  late List<Path> roomPaths = <Path>[];

  @override
  void initState() {
    super.initState();

    memberSearched = Member(
        "Default", "A/B/C", 0, 0, "Default Role", "Default ID", "Status ID");

    xposition = 0;
    yposition = 0;
    scale = 0.6;

    buildingId = 1;

    personName = "";
    floorName = "GroundFloor";

    appUserInstitutionID = 1;
    previousOffset = Offset.zero;
    initialScale = 1.0;

    //loadingPersonRoom();
    buildingOffsetsLoad();
  }

  void changeFloorAndBuilding(floor, building) {
    setState(() {
      floorName = floor;
      buildingName = building;
      print(floorName);
      buildingOffsetsLoad();
    });
  }

  Future<void> buildingOffsetsLoad() async {
    // Load the JSON file
    String jsonString = await rootBundle.loadString('assets/buildings.json');

    roomsOnFloor.clear();

    ///print("offset func reached");

    setState(() {
      jsonData = json.decode(jsonString);

      var building = jsonData?['buildings']?.firstWhere(
          (building) =>
              building['institution_id'] == appUserInstitutionID &&
              //building['building_id'] == buildingId,
              building['building_name'] == buildingName,
          orElse: () => null);

      //print(building);

      if (building != null) {
        var floorData = building[floorName];
        var buildingCoordinates = building["BuildingBoundaries"];

        //print(buildingCoordinates);
        buildingCoordinates?.forEach((item) {
          double x = item[0].toDouble();
          double y = item[1].toDouble();
          buildingBoundaries.add(Offset(x, y));
        });
        //print(buildingBoundaries);

        floorData?.forEach((key, value) {
          List<Offset> points = (value as List).map<Offset>((item) {
            double x = item[0].toDouble();
            double y = item[1].toDouble();
            return Offset(x, y);
          }).toList();

          roomsOnFloor.add(Room(points, key));
        });

        for (Room room in roomsOnFloor) {
          if (room.roomName == memberSearched.room) {
            centering = Offset(100, 100);
          }
        }
      }
    });
  }

  Future<void> roomEventDetailsLoad() async {
    // Load the JSON file
    String jsonString = await rootBundle.loadString('assets/events.json');

    roomsOnFloor.clear();

    ///print("offset func reached");

    setState(() {
      jsonData = json.decode(jsonString);

      var events = jsonData?['buildings']?.firstWhere(
          (events) => events['institution_id'] == appUserInstitutionID,
          //building['building_name'] == memberSearched.building,
          orElse: () => null);

      print(events);

      if (events != null) {}
    });
  }

  void moveRight() {
    setState(() {
      xposition -= 20;
    });
  }

  void moveUp() {
    setState(() {
      yposition += 20;
    });
  }

  void moveDown() {
    setState(() {
      yposition -= 20;
    });
  }

  void moveLeft() {
    setState(() {
      xposition += 20;
    });
  }

  void zoomIn() {
    setState(() {
      scale += 0.3;
    });
  }

  void zoomOut() {
    setState(() {
      scale -= 0.3;
    });
  }

  void getPathAndSize(List<Path> roomPaths, Size size) {
    this.drawingWindowSize = size;
    this.roomPaths = roomPaths;
  }

  Offset scaler(Offset unscaledPoint) {
    return Offset(
        unscaledPoint.dx -
            (drawingWindowSize.width / 2 - scale * (centering.dx)),
        unscaledPoint.dy -
            (drawingWindowSize.height / 2 - scale * (centering.dy)));
  }

  void _onTapDown(TapDownDetails details) {
    print("Tap Down Detected");
    print(details.localPosition);

    if (this.roomPaths[0].contains(scaler(details.localPosition)))
      print("The rectangle has been toucheth");
    else
      print("RIP BOZO");
  }

  void _onScaleStart(ScaleStartDetails details) {
    initialScale = scale;
    previousOffset = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      scale = initialScale * details.scale;

      // Handle panning while scaling
      xposition -= (details.focalPoint.dx - previousOffset.dx).toInt();
      yposition -= (details.focalPoint.dy - previousOffset.dy).toInt();
      previousOffset = details.focalPoint;
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
        GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onTapDown: _onTapDown,
            child: Container(
                width: double.infinity,
                height: 500,
                color: const Color.fromARGB(255, 255, 255, 255),
                child: CustomPaint(
                    painter: PointsPainter(
                  xposition,
                  yposition,
                  scale,
                  roomsOnFloor,
                  memberSearched,
                  buildingBoundaries,
                  centering,
                  getPathAndSize,
                ))))
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
  Member memberSearched;
  List<Offset> buildingBoundaries;
  Offset roomCentering;

  late List<Path> roomPaths = <Path>[];

  final void Function(List<Path>, Size) sendPath;

  final pathPaintStrokeAbsent = Paint()
    ..strokeWidth = 2.0
    ..color = const Color.fromARGB(255, 0, 154, 82)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final pathPaintStrokePresent = Paint()
    ..strokeWidth = 4.0
    ..color = const Color.fromARGB(255, 0, 154, 82)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final pathPaintFill = Paint()
    ..strokeWidth = 2.0
    ..color = const Color.fromARGB(255, 59, 255, 164)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill;

  PointsPainter(
      this.xposition,
      this.yposition,
      this.scale,
      this.roomsOnFloor,
      this.memberSearched,
      this.buildingBoundaries,
      this.roomCentering,
      this.sendPath);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.translate((size.width / 2 - scale * (roomCentering.dx)),
        (size.height / 2 - scale * (roomCentering.dy)));

    final textStyle = TextStyle(
      color: const Color.fromARGB(255, 0, 154, 82),
      fontSize: scale * 20,
    );

    List<Offset> buildingVerticesTranformed = <Offset>[];
    Path buildingPath = Path();
    bool buildingPointFirst = true;

    for (Offset buildingVertex in buildingBoundaries) {
      Offset transformedBuildingVertex = Offset(
          scale * (buildingVertex.dx - xposition),
          scale * (buildingVertex.dy - yposition));
      buildingVerticesTranformed.add(transformedBuildingVertex);
    }

    for (int i = 0; i < buildingVerticesTranformed.length; i++) {
      Offset start = buildingVerticesTranformed[i];
      Offset end = buildingVerticesTranformed[
          (i + 1) % buildingVerticesTranformed.length];

      if (buildingPointFirst) {
        buildingPath.moveTo(start.dx, start.dy);
        buildingPath.lineTo(end.dx, end.dy);
        buildingPointFirst = false;
      } else {
        buildingPath.lineTo(end.dx, end.dy);
      }
    }

    buildingPath.close();
    canvas.drawPath(buildingPath, pathPaintStrokeAbsent);

    for (Room room in roomsOnFloor) {
      String currentRoomName = room.roomName;
      bool firstPoint = true;
      Path roomPath = Path();

      List<Offset> pointsTransformed = room.roomVertices.map((point) {
        return Offset(
            scale * (point.dx - xposition), scale * (point.dy - yposition));
      }).toList();

      for (int i = 0; i < pointsTransformed.length; i++) {
        Offset start = pointsTransformed[i];
        Offset end = pointsTransformed[(i + 1) % pointsTransformed.length];
        if (firstPoint) {
          roomPath.moveTo(start.dx, start.dy);
          roomPath.lineTo(end.dx, end.dy);
          firstPoint = false;
        } else {
          roomPath.lineTo(end.dx, end.dy);
        }
      }

      roomPaths.add(roomPath);

      if (currentRoomName == memberSearched.room && memberSearched.name != "") {
        canvas.drawPath(roomPath, pathPaintStrokePresent);
        canvas.drawPath(roomPath, pathPaintFill);
      } else {
        canvas.drawPath(roomPath, pathPaintStrokeAbsent);
      }

      if (currentRoomName == memberSearched.room && memberSearched.name != "")
        finalTextDisplayed = "Person in\n$currentRoomName";
      else
        finalTextDisplayed = currentRoomName;

      TextSpan textSpan = TextSpan(
        text: finalTextDisplayed,
        style: textStyle,
      );

      TextPainter textPainter = TextPainter(
        textAlign: TextAlign.center,
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );

      sumdX = 0;
      sumdY = 0;
      for (Offset point in pointsTransformed) {
        sumdX += point.dx;
        sumdY += point.dy;
      }
      avgdY = sumdY / pointsTransformed.length;
      avgdX = sumdX / pointsTransformed.length;

      textPainter.paint(
          canvas,
          Offset(
              avgdX - textPainter.width / 2, avgdY - textPainter.height / 2));
    }

    sendPath(roomPaths, size);
  }

  @override
  bool shouldRepaint(covariant PointsPainter oldDelegate) {
    return oldDelegate.xposition != xposition ||
        oldDelegate.yposition != yposition ||
        oldDelegate.scale != scale ||
        oldDelegate.roomsOnFloor != roomsOnFloor ||
        oldDelegate.avgdX != avgdX ||
        oldDelegate.memberSearched != memberSearched ||
        oldDelegate.avgdY != avgdY;
  }
}