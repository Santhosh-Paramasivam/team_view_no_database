// ignore: unnecessary_import
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'custom_datatypes/member.dart';

class Room {
  List<Offset> roomVertices;
  String roomName;

  Room(this.roomVertices, this.roomName);
}

class MapDetailsDisplayWidget extends StatefulWidget {

  const MapDetailsDisplayWidget({super.key});

  @override
  State<MapDetailsDisplayWidget> createState() => MapDetailsDisplayWidgetState();
}

class MapDetailsDisplayWidgetState extends State<MapDetailsDisplayWidget> {
  late int xposition;
  late int yposition;
  late double scale; 

  late Member memberSearched;

  late int buildingId;
  late String floorName;

  late String personName;

  late int appUserInstitutionID;

  Map<String, dynamic>? jsonData;
  List<Room> roomsOnFloor = <Room>[];

  @override
  void initState() {
    super.initState();

    memberSearched = Member("Default", "0/B/C", 0, 0,0);

    xposition = 0;
    yposition = 0;
    scale = 1.0;

    buildingId = 1;

    personName = "";
    floorName = "GroundFloor";

    appUserInstitutionID = 1;

    loadingPersonRoom();
    buildingOffsetsLoad();
  }

  void refreshName(name)
  {
    setState((){
     personName = name;
      if(personName != "")
      {loadingPersonRoom();
      buildingOffsetsLoad();}   
    });
  }

  void changeFloor(floor)
  {
    setState((){
      floorName = floor;
      buildingOffsetsLoad();
    });
  }

  Future<void> loadingPersonRoom() async {
  try {
    // Load the JSON file
    String jsonString = await rootBundle.loadString('assets/members.json');
    // Parse the JSON
    setState(() {
      jsonData = json.decode(jsonString);

      // Find the specific person
      var person = jsonData?['institution_members']?.firstWhere(
        (member) => member['name'] == personName && member["institution_id"] == appUserInstitutionID,
        orElse: () => null,
      );
      /* IMPORTANT COMMENT: ONLY THE INSTITUION OF THE USER MUST BE QUERIED */
      // Check if person is null before accessing its properties
      memberSearched.changeManualLocation(person?['manual_location'] ?? '1/B/C');
      memberSearched.name = person?['name'] ?? 'Default';
      memberSearched.id = person?['id'] ?? 1;
      memberSearched.institutionID = person?['id'] ?? 1; 
      print(person);
      print(personName + appUserInstitutionID.toString());
      print(appUserInstitutionID);
      print(memberSearched.manualLocation + memberSearched.name);
    });
  } catch (e) {
    print('Error loading JSON: $e');
  }
}

  Future<void> buildingOffsetsLoad() async {
    // Load the JSON file
    String jsonString = await rootBundle.loadString('assets/buildings.json');
    
    roomsOnFloor.clear();
    print("offset func reached");

    setState(() {
      jsonData = json.decode(jsonString);

      var building = jsonData?['buildings']?.firstWhere((building) =>
          building['institution_id'] == appUserInstitutionID &&
          //building['building_id'] == buildingId,
          building['building_id'] == memberSearched.buildingID,
          orElse: () => null);

      print(building);
      if (building != null) {
        var floorData = building[memberSearched.floor];
        print(floorData);
        
        floorData?.forEach((key, value) {
          List<Offset> points = (value as List).map<Offset>((item) {
            double x = item[0].toDouble();
            double y = item[1].toDouble();
            return Offset(x, y);
          }).toList();

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
                width: double.infinity,
                height: 500,
                color: const Color.fromARGB(255, 255, 255, 255),
                child: CustomPaint(
                  painter: PointsPainter(
                      xposition, yposition, scale, roomsOnFloor, memberSearched),
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
  //String personRoom;
  //String personName;
  String finalTextDisplayed = "";
  double sumdX = 0;
  double sumdY = 0;
  double avgdY = 0;
  double avgdX = 0;
  double translatedTextX = 0;
  double translatedTextY = 0;
  Member memberSearched;

  PointsPainter(this.xposition, this.yposition, this.scale, this.roomsOnFloor,this.memberSearched);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final textStyle = TextStyle(
      color: const Color.fromARGB(255, 0, 154, 82),
      fontSize: scale*14,
    );

    final personFoundPointPaint = Paint()
      ..strokeWidth = 10.0
      ..color = const Color.fromARGB(255, 5, 244, 133)
      ..strokeCap = StrokeCap.round;

    final personFoundLinePaint = Paint()
      ..strokeWidth = 2.0
      ..color = const Color.fromARGB(255, 3, 246, 132)
      ..strokeCap = StrokeCap.round;

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
        if(currentRoomName == memberSearched.room && memberSearched.name != ""){
          canvas.drawLine(start, end, personFoundLinePaint);
          canvas.drawCircle(start, 4, personFoundPointPaint);
        }
        else
        {
          canvas.drawLine(start, end, linePaint);
          canvas.drawCircle(start, 4, pointPaint);
        }
      }

      if(currentRoomName == memberSearched.room && memberSearched.name != "")
      {
        //finalTextDisplayed = "$personName\nin $currentRoomName";
        finalTextDisplayed = memberSearched.name + "\nin " + currentRoomName;
      }
      else
      {
        finalTextDisplayed = currentRoomName;
      }

      TextSpan textSpan = TextSpan(
      text: finalTextDisplayed,
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
        oldDelegate.memberSearched != memberSearched ||
        oldDelegate.avgdY != avgdY ;
  }
}
