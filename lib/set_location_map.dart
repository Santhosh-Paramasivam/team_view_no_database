import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'firebase_connections/singleton_firestore.dart';
import 'session_data/session_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_data/building_details.dart';
import 'package:logger/logger.dart';
import 'custom_logger.dart';

import 'custom_widgets/cf_toast.dart';
import 'firebase_connections/firestore_error_messages.dart';

import 'custom_widgets/cf_detail_tile.dart';

class Room {
  List<Offset> roomVertices;
  String roomName;

  Room(this.roomVertices, this.roomName);
}

class SetLocationMap extends StatefulWidget {
  const SetLocationMap({super.key});

  @override
  State<SetLocationMap> createState() => SetLocationMapWidgetState();
}

class SetLocationMapWidgetState extends State<SetLocationMap> {
  late int xposition;
  late int yposition;
  late double scale;

  late String floorName;
  late String buildingName;

  late String personName;

  late String appUserInstitutionID;

  Map<String, dynamic>? jsonData;
  List<Room> roomsOnFloor = <Room>[];
  List<Offset> buildingBoundaries = <Offset>[];
  late Offset mapOrigin = const Offset(0, 0);
  late Offset previousOffset;
  late double initialScale;
  late Size drawingWindowSize;

  late bool mapLoadingUp = true;

  late List<Path> roomPaths = <Path>[];
  late List<String> loadedRooms = <String>[];

  String roomClicked = "";

  Stream<QuerySnapshot>? eventStream;
  Stream<QuerySnapshot>? memberStream;

  Logger logger = Logger(
    printer: CustomPrinter("SetLocationState"),
  );

  @override
  void initState() {
    super.initState();

    xposition = 0;
    yposition = 0;
    scale = 0.6;

    buildingName = BuildingDetails.buildings[0];

    personName = "";
    floorName = BuildingDetails.floors[0];

    appUserInstitutionID = SessionDetails.institutionID;
    previousOffset = Offset.zero;
    initialScale = 1.0;

    loadFloors();

    refreshEventStream(buildingName, floorName);
    refreshMemberStream(buildingName, floorName);
  }

  //When a room is double-tapped, this function sets the users location to that room
  Future<bool> updateLocation(String location) async {
    logger.i("Update Location Func Reached");

    bool inRoom;
    try {
      QuerySnapshot userSnapshot = await FirestoreService()
          .firestore
          .collection('institution_members')
          .where('institution_id', isEqualTo: appUserInstitutionID)
          .where('id', isEqualTo: SessionDetails.id)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        putToast("User data not available");
        logger.e("User data not available");
      }

      Map<String, dynamic> userData = userSnapshot.docs[0].data() as Map<String, dynamic>;

      if (userData['rfid_location'] != location) {
        inRoom = true;
      } else {
        inRoom = !userData['in_room'];
      }

      await FirestoreService()
          .firestore
          .collection('institution_members')
          .doc(userSnapshot.docs[0].id)
          .update({
        'rfid_location': location,
        'in_room': inRoom,
        'last_location_entry': Timestamp.now()
      });

      return inRoom;
    } on FirebaseException catch (e) {
      putToast(
          "Error Updating Location : ${FirestoreUserErrorMessages.errorCodeTranslations[e.code]}");
      logger.e("${e.code} ${e.message}");
      return false;
    }
  }

  void changeFloorAndBuilding(floor, building) {
    setState(() {
      mapLoadingUp = true;
      floorName = floor;
      buildingName = building;
      roomClicked = "";
      logger.d(floorName);
      loadFloors();

      //Refreshing the event and member streams to the new floor
      refreshEventStream(buildingName, floorName);
      refreshMemberStream(buildingName, floorName);
    });
  }

  void refreshEventStream(String buildingName, String floorName) {
    try {
      eventStream = FirestoreService()
          .firestore
          .collection("events")
          .where("institution_id", isEqualTo: appUserInstitutionID)
          .where("building", isEqualTo: buildingName)
          .where("floor", isEqualTo: floorName)
          .snapshots();
    } on FirebaseException catch (e) {
      putToast("${FirestoreUserErrorMessages.errorCodeTranslations[e.code]}");
      logger.e("${e.code} ${e.message}");

      eventStream = const Stream.empty();
    }
  }

  void refreshMemberStream(String buildingName, String floorName) {
    try {
      memberStream = FirestoreService()
          .firestore
          .collection("institution_members")
          .where("institution_id", isEqualTo: appUserInstitutionID)
          .where("rfid_location", isGreaterThanOrEqualTo: "$buildingName/$floorName")
          .where("rfid_location", isLessThanOrEqualTo: "$buildingName/$floorName\uf8ff")
          .snapshots();
    } on FirebaseException catch (e) {
      putToast("${FirestoreUserErrorMessages.errorCodeTranslations[e.code]}");
      logger.e("${e.code} ${e.message}");

      memberStream = const Stream.empty();
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

      QuerySnapshot selectedBuildingSnapshot = await FirestoreService()
          .firestore
          .collection('institution_buildings')
          .doc(institutionDocName)
          .collection('buildings')
          .where("building_name", isEqualTo: buildingName)
          .limit(1)
          .get();

      if (selectedBuildingSnapshot.docs.isEmpty) {
        putToast("Member building not found in institution");
        logger.f("Member building not found in the institution : $appUserInstitutionID");
      }

      QueryDocumentSnapshot memberBuilding = selectedBuildingSnapshot.docs.first;
      buildingDocName = memberBuilding.id;
      building = memberBuilding.data() as Map<String, dynamic>;

      logger.d("institutionDocName : $institutionDocName");
      logger.d("memberSearched building : $buildingName");
      logger.d("buildingBoundariesInt : $building");

      //Decodes building boundaries into list of coordinates
      buildingBoundariesInt = jsonDecode(building['building_boundaries'])
          .map<List<int>>((item) => List<int>.from(item))
          .toList();

      //Coordinate values converted to Offset
      for (List<int> point in buildingBoundariesInt) {
        buildingBoundaries.add(Offset(point[0].toDouble(), point[1].toDouble()));
      }

      QuerySnapshot selectedFloorSnapshot = await FirestoreService()
          .firestore
          .collection('institution_buildings')
          .doc(institutionDocName)
          .collection('buildings')
          .doc(buildingDocName)
          .collection('floors')
          .where('floor_name', isEqualTo: floorName)
          .limit(1)
          .get();

      if (selectedFloorSnapshot.docs.isEmpty) {
        putToast("Member floor not found in the institution");
        logger.f("Member floor not found in the institution : $appUserInstitutionID");
      }

      QueryDocumentSnapshot memberFloor = selectedFloorSnapshot.docs.first;

      //Loads floor map values
      floor = memberFloor.data() as Map<String, dynamic>;
      floor = json.decode(floor['rooms_on_floor']) as Map<String, dynamic>;
    } on FirebaseException catch (e) {
      putToast("${FirestoreUserErrorMessages.errorCodeTranslations[e.code]}");
      logger.e("${e.code} ${e.message}");
      return;
    }

    floor.forEach((key, value) {
      List<Offset> points = (value as List).map<Offset>((item) {
        double x = item[0].toDouble();
        double y = item[1].toDouble();
        return Offset(x, y);
      }).toList();

      roomsOnFloor.add(Room(points, key));
    });

    setState(() {
      mapLoadingUp = false;
    });
  }

  void getPathAndSize(List<Path> roomPaths, Size size, List<String> loadedRooms) {
    this.drawingWindowSize = size;
    this.roomPaths = roomPaths;
    this.loadedRooms = loadedRooms;
  }

  Offset scaler(Offset unscaledPoint) {
    return Offset(unscaledPoint.dx - (drawingWindowSize.width / 2 - scale * (mapOrigin.dx)),
        unscaledPoint.dy - (drawingWindowSize.height / 2 - scale * (mapOrigin.dy)));
  }

  void _onTapDown(TapDownDetails details) {
    for (int i = 0; i < this.roomPaths.length; i++) {
      if (this.roomPaths[i].contains(scaler(details.localPosition))) {
        String location = "${this.buildingName}/${this.floorName}/${this.loadedRooms[i]}";

        logger.d(location);

        setState(() {
          roomClicked = this.loadedRooms[i];
        });
      }
    }
  }

  void _onDoubleTapDown(TapDownDetails details) async {
    for (int i = 0; i < this.roomPaths.length; i++) {
      if (this.roomPaths[i].contains(scaler(details.localPosition))) {
        String location = "${this.buildingName}/${this.floorName}/${this.loadedRooms[i]}";

        logger.d(location);

        bool enteredRoom = await updateLocation(location);
        logger.d("done");

        if (enteredRoom) {
          putToast("You entered $location");
        } else {
          putToast("You exited $location");
        }
      }
    }
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
    return Column(
      children: [
        mapLoadingUp
            ? Container(
                width: double.infinity,
                height: 500,
                color: const Color.fromARGB(255, 255, 255, 255),
                child: const Center(child: CircularProgressIndicator()))
            : StreamBuilder(
                stream: eventStream,
                builder: (context, eventSnapshot) {
                  if (eventSnapshot.hasError) {
                    logger.e("eventSnapshot has an error");

                    return Container(
                      width: double.infinity,
                      height: 100,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      child: const Center(child: Text("Error fetching data")),
                    );
                  }

                  if (eventSnapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                        width: double.infinity,
                        height: 500,
                        color: const Color.fromARGB(255, 255, 255, 255),
                        child: const Center(child: CircularProgressIndicator()));
                  }

                  if (!eventSnapshot.hasData) {
                    logger.e("User snapshot doesn't have any data");
                    return RepaintBoundary(
                        child: GestureDetector(
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      onDoubleTapDown: _onDoubleTapDown,
                      onTapDown: _onTapDown,
                      child: Container(
                        width: double.infinity,
                        height: 400,
                        color: const Color.fromARGB(255, 255, 255, 255),
                        child: CustomPaint(
                          painter: MapPainter(
                              xposition,
                              yposition,
                              scale,
                              roomsOnFloor,
                              buildingBoundaries,
                              mapOrigin,
                              getPathAndSize,
                              roomClicked,
                              buildingName,
                              floorName, {}),
                        ),
                      ),
                    ));
                  }

                  Map<String, Map<String, dynamic>> eventDetails = {};
                  Map<String, dynamic> eventDetail = {};

                  for (var doc in eventSnapshot.data!.docs) {
                    eventDetail = doc.data() as Map<String, dynamic>;
                    String location = eventDetail['room'];
                    eventDetails.addAll({location: eventDetail});
                  }

                  logger.d(eventDetails);

                  return StreamBuilder(
                    stream: memberStream,
                    builder: (context, memberSnapshot) {
                      if (memberSnapshot.hasError) {
                        logger.e("member stream snapshot has an error");

                        return Container(
                          width: double.infinity,
                          height: 100,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: const Center(child: Text("Error fetching data")),
                        );
                      }

                      if (memberSnapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                            width: double.infinity,
                            height: 500,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            child: const Center(child: CircularProgressIndicator()));
                      }

                      if (!memberSnapshot.hasData || memberSnapshot.data!.docs.isEmpty) {
                        logger.w("member stream snapshot is empty");

                        return RepaintBoundary(
                            child: GestureDetector(
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onDoubleTapDown: _onDoubleTapDown,
                          onTapDown: _onTapDown,
                          child: Container(
                            width: double.infinity,
                            height: 400,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            child: CustomPaint(
                              painter: MapPainter(
                                  xposition,
                                  yposition,
                                  scale,
                                  roomsOnFloor,
                                  buildingBoundaries,
                                  mapOrigin,
                                  getPathAndSize,
                                  roomClicked,
                                  buildingName,
                                  floorName,
                                  eventDetails),
                            ),
                          ),
                        ));
                      }

                      // All attendees in the floor are added to a list
                      List<Map<String, dynamic>> attendeesList = [];
                      for (var doc in memberSnapshot.data!.docs) {
                        logger.d(doc.data() as Map<String, dynamic>);
                        Map<String, dynamic> attendee = doc.data() as Map<String, dynamic>;

                        attendeesList.add(attendee);
                      }

                      logger.d("Member : ");
                      logger.d(memberSnapshot.data!.size);

                      return Column(children: [
                        GestureDetector(
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onDoubleTapDown: _onDoubleTapDown,
                          onTapDown: _onTapDown,
                          child: Container(
                            width: double.infinity,
                            height: 400,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            child: CustomPaint(
                              painter: MapPainter(
                                  xposition,
                                  yposition,
                                  scale,
                                  roomsOnFloor,
                                  buildingBoundaries,
                                  mapOrigin,
                                  getPathAndSize,
                                  roomClicked,
                                  buildingName,
                                  floorName,
                                  eventDetails),
                            ),
                          ),
                        ),
                        EventDetails(
                            eventDetails, roomClicked, floorName, buildingName, attendeesList),
                      ]);
                    },
                  );
                },
              ),
      ],
    );
  }
}

class MapPainter extends CustomPainter {
  final int xposition;
  final int yposition;
  final double scale;
  final List<Room> roomsOnFloor;
  String finalTextDisplayed = "";
  double sumdX = 0;
  double sumdY = 0;
  double avgdY = 0;
  double avgdX = 0;
  List<Offset> buildingBoundaries;
  Offset roomCentering;

  late List<Path> roomPaths = <Path>[];
  late List<String> loadedRooms = <String>[];

  String roomClicked;
  String buildingName;
  String floorName;

  final void Function(List<Path>, Size, List<String>) sendPath;

  Map<String, Map<String, dynamic>> eventDetails = {};

  final Map<int, Color> eventColours = {
    0: const Color.fromARGB(255, 255, 223, 186),
    1: const Color.fromARGB(255, 59, 255, 164),
    2: const Color.fromARGB(255, 53, 231, 234),
    3: const Color.fromARGB(255, 248, 206, 129),
    4: const Color.fromARGB(255, 211, 210, 210),
    5: const Color.fromARGB(255, 255, 223, 233),
    6: const Color.fromARGB(255, 228, 255, 228),
    7: const Color.fromARGB(255, 223, 239, 253),
    8: const Color.fromARGB(255, 255, 245, 153),
    9: const Color.fromARGB(255, 255, 218, 185)
  };

  final buildingBorderPaint = Paint()
    ..strokeWidth = 1.5
    ..color = const Color.fromARGB(255, 0, 154, 82)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final roomBorderPaint = Paint()
    ..strokeWidth = 3.0
    ..color = const Color.fromARGB(255, 0, 154, 82)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final roomSelectedBorderPaint = Paint()
    ..strokeWidth = 4.5
    ..color = const Color.fromARGB(255, 0, 154, 82)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final roomFillPaint = Paint()
    ..strokeWidth = 3.0
    ..color = const Color.fromARGB(255, 59, 255, 164)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill;

  MapPainter(
      this.xposition,
      this.yposition,
      this.scale,
      this.roomsOnFloor,
      this.buildingBoundaries,
      this.roomCentering,
      this.sendPath,
      this.roomClicked,
      this.buildingName,
      this.floorName,
      this.eventDetails);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final textStyle = TextStyle(
      color: const Color.fromARGB(255, 0, 154, 82),
      fontSize: scale * 20,
    );

    // chosen colours
    // black = Color.fromARGB(255, 0, 0, 0);
    // Color.fromARGB(255, 38, 38, 38);
    // Color.fromARGB(255, 53, 231, 234);
    // Color.fromARGB(255, 252, 177, 38);
    // Color.fromARGB(255, 211, 210, 210);
    // lavender blush Color.fromARGB(255, 255, 223, 233);
    // honey dew Color.fromARGB(255, 228, 255, 228);
    // alice blue Color.fromARGB(255, 223, 239, 253);
    // lemon chiffon Color.fromARGB(255, 255, 245, 153);
    // peach puff Color.fromARGB(255, 255, 218, 185);

    roomFillPaint.color = eventColours[9]!;
    List<Offset> buildingVerticesTranformed = <Offset>[];
    Path buildingPath = Path();
    bool buildingPointFirst = true;

    // building boundaries transformed
    for (Offset buildingVertex in buildingBoundaries) {
      Offset transformedBuildingVertex =
          Offset(scale * (buildingVertex.dx - xposition), scale * (buildingVertex.dy - yposition));
      buildingVerticesTranformed.add(transformedBuildingVertex);
    }

    canvas.translate((size.width / 2 - scale * (roomCentering.dx)),
        (size.height / 2 - scale * (roomCentering.dy)));

    // building boundaries drawn
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
    canvas.drawPath(buildingPath, buildingBorderPaint);

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

      if (noneInside) {
        continue;
      }

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
      loadedRooms.add(currentRoomName);

      String eventName;
      if (eventDetails.isEmpty || eventDetails[currentRoomName] == null) {
        roomFillPaint.color = Colors.white;
        eventName = "";
      } else {
        eventName = eventDetails[currentRoomName]!['name'];
        int colourIndex = eventName.hashCode % 10;
        roomFillPaint.color = eventColours[colourIndex]!;
      }

      if (currentRoomName == roomClicked) {
        canvas.drawPath(roomPath, roomSelectedBorderPaint);
      } else {
        canvas.drawPath(roomPath, roomBorderPaint);
      }

      if (eventDetails.isNotEmpty || eventDetails[currentRoomName] != null) {
        canvas.drawPath(roomPath, roomFillPaint);
      }

      TextSpan roomNameSpan = TextSpan(
        text: currentRoomName,
        style: textStyle,
      );

      TextPainter roomNamePainter = TextPainter(
        textAlign: TextAlign.center,
        text: roomNameSpan,
        textDirection: TextDirection.ltr,
      );

      roomNamePainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );

      TextSpan eventNameSpan = TextSpan(
        text: eventName,
        style: textStyle,
      );

      TextPainter eventNamePainter = TextPainter(
        textAlign: TextAlign.center,
        text: eventNameSpan,
        textDirection: TextDirection.ltr,
      );

      eventNamePainter.layout(
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

      if (eventDetails.isEmpty || eventDetails[currentRoomName] == null) {
        roomNamePainter.paint(
            canvas, Offset(avgdX - roomNamePainter.width / 2, avgdY - roomNamePainter.height / 2));
      } else {
        roomNamePainter.paint(
            canvas,
            Offset(avgdX - roomNamePainter.width / 2,
                avgdY - roomNamePainter.height / 2 - scale * 13));
        eventNamePainter.paint(
            canvas,
            Offset(avgdX - eventNamePainter.width / 2,
                avgdY - eventNamePainter.height / 2 + scale * 13));
      }
    }

    sendPath(roomPaths, size, loadedRooms);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.xposition != xposition ||
        oldDelegate.yposition != yposition ||
        oldDelegate.scale != scale ||
        oldDelegate.roomsOnFloor != roomsOnFloor ||
        oldDelegate.roomClicked != roomClicked;
  }
}

class EventDetails extends StatelessWidget {
  List<ListTile> eventDetailTiles = <ListTile>[];

  Map<String, Map<String, dynamic>> eventDetails = {};
  String roomClicked;
  String floorName;
  String buildingName;
  List<Map<String, dynamic>> attendeesList;
  late int numberOfAttendees = 0;

  List<Map<String, dynamic>> getAttendeesInRoom(
      List<Map<String, dynamic>> attendeesList, String location) {
    List<Map<String, dynamic>> attendeesInRoom = [];
    for (Map<String, dynamic> attendee in attendeesList) {
      if (attendee['rfid_location'] == location && attendee['in_room'] == true) {
        attendeesInRoom.add(attendee);
        numberOfAttendees++;
      }
    }

    return attendeesInRoom;
  }

  void displayEvent() {
    //if there are no events for the room clicked, display "No events"
    if (eventDetails[roomClicked] == null) {
      eventDetailTiles.add(DetailsTile("No Events"));
    } else {
      eventDetailTiles.add(DetailsTile(
        "Event Name : ${eventDetails[roomClicked]!['name']}",
      ));
    }
  }

  void displayAttendeeCount() {
    eventDetailTiles.add(DetailsTile("Number of Attendees : $numberOfAttendees"));
  }

  void displayAttendeeNames(List<Map<String, dynamic>> attendeesInRoom) {
    for (Map<String, dynamic> attendee in attendeesInRoom) {
      eventDetailTiles.add(DetailsTile(attendee['name']));
    }
  }

  EventDetails(
      this.eventDetails, this.roomClicked, this.floorName, this.buildingName, this.attendeesList,
      {super.key}) {
    displayEvent();

    String location = "$buildingName/$floorName/$roomClicked";
    List<Map<String, dynamic>> attendeesInRoom = getAttendeesInRoom(attendeesList, location);

    displayAttendeeCount();

    displayAttendeeNames(attendeesInRoom);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey, width: 1),
        ),
        width: 500,
        height: 200,
        child: ListView(padding: EdgeInsets.zero, children: eventDetailTiles));
  }
}
