import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'firebase_connections/singleton_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'session_data/session_details.dart';

import 'package:logger/logger.dart';
import 'custom_logger.dart';

import 'custom_widgets/cf_toast.dart';

import 'firebase_connections/firestore_error_messages.dart';


class Member {
  late String name;
  late String rfidLocation;
  late String institutionID;
  late String id;
  late String floor;
  late String building;
  late String room;
  late String role;
  late String memberID;
  late String status;

  void setRFIDLocation(String newRFIDLocation) {
    rfidLocation = newRFIDLocation;
    List<String> rfidLocationList = rfidLocation.split("/");
    building = rfidLocationList[0];
    floor = rfidLocationList[1];
    room = rfidLocationList[2];
  }
}

class Room {
  List<Offset> roomVertices;
  String roomName;
  late Offset roomCenter;

  Room(this.roomVertices, this.roomName) {
    // Following code calculates the room center
    double sumdX = 0;
    double sumdY = 0;
    for (Offset roomVertex in roomVertices) {
      sumdX += roomVertex.dx;
      sumdY += roomVertex.dy;
    }

    this.roomCenter = Offset(sumdX / roomVertices.length, sumdY / roomVertices.length);
  }
}

class MemberLocationMap extends StatefulWidget {
  const MemberLocationMap({super.key});

  @override
  State<MemberLocationMap> createState() => MemberLocationMapState();
}

class MemberLocationMapState extends State<MemberLocationMap> {
  late int xposition;
  late int yposition;
  late double scale;

  late Member memberSearched;

  late String personName;

  late String appUserInstitutionID;

  Map<String, dynamic>? jsonData;
  List<Room> roomsOnFloor = <Room>[];
  List<Offset> buildingBoundaries = <Offset>[];
  late Offset center = const Offset(0, 0);
  late Offset previousOffset;
  late double initialScale; // To keep track of the previous drag position
  late Size drawingWindowSize;

  late bool mapLoadingUp;

  late List<Path> roomPaths = <Path>[];

  Map<String, dynamic> prevPersonDetails = <String, dynamic>{};

  Logger logger = Logger(printer: CustomPrinter("MemberLocationMapState"));

  @override
  void initState() {
    super.initState();

    memberSearched = Member();
    memberSearched.setRFIDLocation(SessionDetails.rfidLocation);

    xposition = 0;
    yposition = 0;
    scale = 0.6;
    personName = SessionDetails.name;

    appUserInstitutionID = SessionDetails.institutionID;
    previousOffset = Offset.zero;
    initialScale = 1.0;

    loadFloors();
    mapLoadingUp = true;
  }

  void refreshName(name) async {
    logger.d("Refresh Name Function Called");
    setState(() {
      personName = name;
      xposition = 0;
      yposition = 0;
      scale = 0.6;

      mapLoadingUp = true;
    });

    await loadFloors();

    setState(() {
      mapLoadingUp = false;
    });
  }

  Stream<QuerySnapshot> fetchUsersStream() {
    Stream<QuerySnapshot> userStream;
    try {
      userStream = FirestoreService()
          .firestore
          .collection("institution_members")
          .where("name", isEqualTo: personName)
          .where("institution_id", isEqualTo: appUserInstitutionID)
          .limit(1)
          .snapshots();

      return userStream;
    } on FirebaseException catch (e) {
      putToast("${FirestoreUserErrorMessages.errorCodeTranslations[e.code]}");
      logger.e("${e.code} ${e.message}");
      return const Stream.empty();
    }
  }

  Future<void> loadFloors() async {
    roomsOnFloor.clear();

    String institutionDocName = '';
    String buildingDocName = '';
    Map<String, dynamic> building = {};
    List<List<int>> buildingBoundariesInt = [];
    late Map<String, dynamic> floor = {};

    try {
      QuerySnapshot institutionBuildingSnapshot = await FirestoreService()
          .firestore
          .collection('institution_buildings')
          .where('institution_id', isEqualTo: appUserInstitutionID)
          .limit(1)
          .get();

      if (institutionBuildingSnapshot.docs.isEmpty) {
        putToast("No buildings in the institution");
        logger.f("No buildings in the institution $appUserInstitutionID");
      }

      QueryDocumentSnapshot institutionBuilding = institutionBuildingSnapshot.docs.first;
      institutionDocName = institutionBuilding.id;

      QuerySnapshot memberBuildingSnapshot = await FirestoreService()
          .firestore
          .collection('institution_buildings')
          .doc(institutionDocName)
          .collection('buildings')
          .where("building_name", isEqualTo: memberSearched.building)
          .limit(1)
          .get();

      if (memberBuildingSnapshot.docs.isEmpty) {
        putToast("Member building not found in institution");
        logger.f("Member building not found in the institution : $appUserInstitutionID");
      }

      QueryDocumentSnapshot memberBuilding = memberBuildingSnapshot.docs.first;
      buildingDocName = memberBuilding.id;
      building = memberBuilding.data() as Map<String, dynamic>;

      logger.d("institutionDocName : $institutionDocName");
      logger.d("memberSearched building : ${memberSearched.building}");
      logger.d("buildingBoundariesInt : $building");

      //Decodes building boundaries into list of coordinates
      buildingBoundariesInt = jsonDecode(building['building_boundaries'])
          .map<List<int>>((item) => List<int>.from(item))
          .toList();

      //Coordinate values converted to Offset
      for (List<int> point in buildingBoundariesInt) {
        buildingBoundaries.add(Offset(point[0].toDouble(), point[1].toDouble()));
      }

      QuerySnapshot memberFloorSnapshot = await FirestoreService()
          .firestore
          .collection('institution_buildings')
          .doc(institutionDocName)
          .collection('buildings')
          .doc(buildingDocName)
          .collection('floors')
          .where('floor_name', isEqualTo: memberSearched.floor)
          .limit(1)
          .get();

      if (memberFloorSnapshot.docs.isEmpty) {
        putToast("Member floor not found in the institution");
        logger.f("Member floor not found in the institution : $appUserInstitutionID");
      }

      QueryDocumentSnapshot memberFloor = memberFloorSnapshot.docs.first;

      //Loads floor map values
      floor = memberFloor.data() as Map<String, dynamic>;
      floor = json.decode(floor['rooms_on_floor']) as Map<String, dynamic>;
    } on FirebaseException catch (e) {
      putToast("${FirestoreUserErrorMessages.errorCodeTranslations[e.code]}");
      logger.e("${e.code} ${e.message}");
      return;
    }

    //Floor map converted to offset values
    floor.forEach((key, value) {
      List<Offset> points = (value as List).map<Offset>((item) {
        double x = item[0].toDouble();
        double y = item[1].toDouble();
        return Offset(x, y);
      }).toList();

      roomsOnFloor.add(Room(points, key));
    });

    //Sets map center to the room the member is in
    for (Room room in roomsOnFloor) {
      if (room.roomName == memberSearched.room) {
        center = room.roomCenter;
      }
    }

    setState(() {
      mapLoadingUp = false;
    });
  }

  void getPathAndSize(List<Path> roomPaths, Size size) {
    this.drawingWindowSize = size;
    this.roomPaths = roomPaths;
  }

  Offset scaler(Offset unscaledPoint) {
    return Offset(unscaledPoint.dx - (drawingWindowSize.width / 2 - scale * (center.dx)),
        unscaledPoint.dy - (drawingWindowSize.height / 2 - scale * (center.dy)));
  }

  void _onScaleStart(ScaleStartDetails details) {
    initialScale = scale;
    previousOffset = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if ((details.scale - scale).abs() > 0.01 ||
        (details.focalPoint - previousOffset).distance > 5) {
      setState(() {
        scale = initialScale * details.scale;
        xposition -= ((1 / scale) * (details.focalPoint.dx - previousOffset.dx)).toInt();
        yposition -= ((1 / scale) * (details.focalPoint.dy - previousOffset.dy)).toInt();
        previousOffset = details.focalPoint;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Divider(height: 1),
      StreamBuilder<QuerySnapshot>(
        stream: fetchUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            logger.e("Error fetching searched user data");

            return Container(
                width: double.infinity,
                height: 500,
                color: const Color.fromARGB(255, 255, 255, 255),
                child: const Center(child: Text("Error fetching user data")));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            logger.e("User snapshot doesn't have any data");

            return Container(
                width: double.infinity,
                height: 500,
                color: const Color.fromARGB(255, 255, 255, 255),
                child: const Center(child: Text("User not found")));
          }

          var doc = snapshot.data!.docs.first;
          Map<String, dynamic> personDetails = doc.data() as Map<String, dynamic>;

          final eq = const DeepCollectionEquality().equals;

          if (!eq(personDetails, prevPersonDetails)) {
            logger.d("User data refreshed");

            memberSearched.setRFIDLocation(personDetails['rfid_location']);
            memberSearched.name = personDetails['name'];
            memberSearched.institutionID = personDetails['institution_id'];
            memberSearched.id = personDetails['id'];

            logger.d("memberSearched.room : ${memberSearched.room}");
            logger.d("memberSearched.floor : ${memberSearched.floor}");
            logger.d("memberSearched.building : ${memberSearched.building}");

            prevPersonDetails = Map.from(personDetails);

            for (Room room in roomsOnFloor) {
              if (room.roomName == memberSearched.room) {
                center = room.roomCenter;
              }
            }
          }
          return GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Container(
                  width: double.infinity,
                  height: 400,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: mapLoadingUp
                      ? const Center(child: CircularProgressIndicator())
                      : CustomPaint(
                          painter: PointsPainter(
                          xposition,
                          yposition,
                          scale,
                          roomsOnFloor,
                          memberSearched,
                          buildingBoundaries,
                          center,
                          getPathAndSize,
                        ))));
        },
      ),
    ]);
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

  final roomBorderPaint = Paint()
    ..strokeWidth = 2.0
    ..color = const Color.fromARGB(255, 0, 154, 82)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final roomBorderMemberPresentPaint = Paint()
    ..strokeWidth = 4.0
    ..color = const Color.fromARGB(255, 0, 154, 82)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final roomFillPaint = Paint()
    ..strokeWidth = 2.0
    ..color = const Color.fromARGB(255, 59, 255, 164)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill;

  PointsPainter(this.xposition, this.yposition, this.scale, this.roomsOnFloor, this.memberSearched,
      this.buildingBoundaries, this.roomCentering, this.sendPath);

  @override
  void paint(Canvas canvas, Size size) {
    //Defines area for drawing
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    //Centers the map on the searched member's room
    canvas.translate((size.width / 2 - scale * (roomCentering.dx)),
        (size.height / 2 - scale * (roomCentering.dy)));

    final textStyle = TextStyle(
      color: const Color.fromARGB(255, 0, 154, 82),
      fontSize: scale * 20,
    );

    List<Offset> buildingVerticesTranformed = <Offset>[];
    Path buildingPath = Path();
    bool buildingPointFirst = true;

    //building boundaries scaled
    for (Offset buildingVertex in buildingBoundaries) {
      Offset transformedBuildingVertex =
          Offset(scale * (buildingVertex.dx - xposition), scale * (buildingVertex.dy - yposition));
      buildingVerticesTranformed.add(transformedBuildingVertex);
    }

    //building boundaries drawn
    for (int i = 0; i < buildingVerticesTranformed.length; i++) {
      Offset start = buildingVerticesTranformed[i];
      Offset end = buildingVerticesTranformed[(i + 1) % buildingVerticesTranformed.length];

      if (buildingPointFirst) {
        buildingPath.moveTo(start.dx, start.dy);
        buildingPath.lineTo(end.dx, end.dy);
        buildingPointFirst = false;
      } else {
        buildingPath.lineTo(end.dx, end.dy);
      }
    }

    buildingPath.close();
    canvas.drawPath(buildingPath, roomBorderPaint);

    for (Room room in roomsOnFloor) {
      String currentRoomName = room.roomName;
      bool firstPoint = true;
      Path roomPath = Path();

      List<Offset> pointsTransformed = room.roomVertices.map((point) {
        return Offset(scale * (point.dx - xposition), scale * (point.dy - yposition));
      }).toList();

      //checks if the room vertices are within boundaries, if not, the room is skipped
      bool noneInside = true;
      for (int i = 0; i < pointsTransformed.length; i++) {
        if ((pointsTransformed[i].dx < size.width - (size.width / 2 - scale * (roomCentering.dx)) &&
                pointsTransformed[i].dx > -1 * (size.width / 2 - scale * (roomCentering.dx))) &&
            (pointsTransformed[i].dy <
                    size.height - (size.height / 2 - scale * (roomCentering.dy)) &&
                pointsTransformed[i].dy > -1 * (size.height / 2 - scale * (roomCentering.dy)))) {
          noneInside = false;
          break;
        }
      }

      if (noneInside) continue;

      //room drawn
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
        canvas.drawPath(roomPath, roomBorderMemberPresentPaint);
        canvas.drawPath(roomPath, roomFillPaint);
      } else {
        canvas.drawPath(roomPath, roomBorderPaint);
      }

      if (currentRoomName == memberSearched.room && memberSearched.name != "") {
        finalTextDisplayed = "Person in\n$currentRoomName";
      } else {
        finalTextDisplayed = currentRoomName;
      }

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
          canvas, Offset(avgdX - textPainter.width / 2, avgdY - textPainter.height / 2));
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
        oldDelegate.buildingBoundaries != buildingBoundaries ||
        oldDelegate.avgdY != avgdY;
  }
}
