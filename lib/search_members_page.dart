import 'package:flutter/material.dart';

import 'package:logger/logger.dart';

import 'display_location_map.dart';
import 'search_members_bar.dart';
import 'drawer.dart';
import 'custom_logger.dart';
import 'custom_widgets/cf_detail_tile.dart';
import 'custom_widgets/cf_toast.dart';

import 'firebase_connections/singleton_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'session_data/session_details.dart';

import 'package:collection/collection.dart';

import 'firebase_connections/firestore_error_messages.dart';

import 'dart:async';

import 'package:internet_connection_checker/internet_connection_checker.dart';

class Member {
  late String name;
  late String rfidLocation;
  late String institutionID;
  late String floor;
  late String building;
  late String room;
  late String role;
  late String memberID;
  late String status;
  late Timestamp lastLocationEntry;
  late bool inRoom;

  void setRFIDLocation(String newRFIDLocation) {
    rfidLocation = newRFIDLocation;
    List<String> rfidLocationList = rfidLocation.split("/");
    building = rfidLocationList[0];
    floor = rfidLocationList[1];
    room = rfidLocationList[2];
  }
}

class MemberSearchPage extends StatefulWidget {
  const MemberSearchPage({super.key});

  @override
  State<MemberSearchPage> createState() => _MemberSearchPageState();
}

class _MemberSearchPageState extends State<MemberSearchPage> {
  late String name;
  Map<String, dynamic>? jsonData;

  Logger logger = Logger(printer: CustomPrinter("MemberSearchPage"));

  late bool doDisplayMember;

  late Member memberForMemberDetails;
  late String appUserInstitutionID;

  final GlobalKey<MapDetailsDisplayWidgetState> _mapDetailsDisplayWidget =
      GlobalKey<MapDetailsDisplayWidgetState>();
  final GlobalKey<MemberSearchBarState> _memberSearchBar = GlobalKey<MemberSearchBarState>();

  Map<String, dynamic> prevPersonDetails = <String, dynamic>{};

  bool prevInternetConnected = true;

  @override
  initState() {
    super.initState();
    memberForMemberDetails = Member();

    appUserInstitutionID = SessionDetails.institution_id;

    displayMemberNew(SessionDetails.name);
    initTimer();
  }

  void displayMemberNew(String memberName) async {
    //This updates the member details
    setState(() {
      name = memberName;
    });

    //This updates the map displayed
    _mapDetailsDisplayWidget.currentState?.refreshName(name);
  }

  Stream<QuerySnapshot> fetchUsersStream() {
    Stream<QuerySnapshot> usersStream;
    try {
      usersStream = FirestoreService()
          .firestore
          .collection("institution_members")
          .where("name", isEqualTo: name)
          .where("institution_id", isEqualTo: appUserInstitutionID)
          .limit(1)
          .snapshots();

      return usersStream;
    } on FirebaseException catch (e) {
      logger.w("Firebase Exception : ${e.message} ${e.code}");
      putToast(
          "Warning : Unable to load user, ${FirestoreUserErrorMessages.errorCodeTranslations[e.code]}");
      return const Stream.empty();
    }
  }

  Timer? timer;

  void initTimer() {
    if (timer != null && timer!.isActive) return;

    timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      setState(() {});
      if (await checkInternet()) {
        if (!prevInternetConnected) {
          logger.d("Internet connection");
          putToast("Back Online!");
        }

        prevInternetConnected = true;
      } else {
        logger.d("No internet connection");

        if (prevInternetConnected) {
          putToast("Warning : No internet connection, using cached results");
        }

        prevInternetConnected = false;
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<bool> checkInternet() async {
    final bool isConnected = await InternetConnectionChecker.instance.hasConnection;
    return isConnected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: MemberSearchBar(_memberSearchBar, displayMemberNew),
        drawer: CampusFindDrawer(),
        body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: fetchUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.none) {
                      putToast("Connection couldn't be established!");
                      logger.w("Connection couldn't be established to Firestore");

                      return Container(
                          width: double.infinity,
                          height: 100,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: const Center(child: CircularProgressIndicator()));
                    }

                    if (snapshot.hasError) {
                      putToast("Connection couldn't be established!");
                      logger.w("Firestore stream snapshot has errors");

                      return Container(
                          width: double.infinity,
                          height: 100,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: const Center(child: CircularProgressIndicator()));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                          width: double.infinity,
                          height: 100,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: const Center(child: CircularProgressIndicator()));
                    }

                    var doc = snapshot.data!.docs.first;
                    Map<String, dynamic> personDetails = doc.data() as Map<String, dynamic>;

                    final eq = const DeepCollectionEquality().equals;

                    if (!eq(personDetails, prevPersonDetails)) {
                      logger.d("StreamBuilder Update Code Reached");

                      memberForMemberDetails.name = personDetails['name'];
                      memberForMemberDetails.setRFIDLocation(personDetails['rfid_location']);
                      memberForMemberDetails.institutionID = appUserInstitutionID;
                      memberForMemberDetails.role = personDetails['user_role'];
                      memberForMemberDetails.status = personDetails['status'];

                      logger.d(personDetails['last_location_entry']);
                      logger.d(
                          Timestamp.now().seconds - personDetails['last_location_entry'].seconds);

                      memberForMemberDetails.lastLocationEntry =
                          personDetails['last_location_entry'];

                      memberForMemberDetails.inRoom = personDetails['in_room'];

                      // To be removed eventually in favour of user-chosen attribute system
                      if (memberForMemberDetails.role == "Professor") {
                        memberForMemberDetails.memberID = personDetails['faculty_id'];
                      } else if (memberForMemberDetails.role == "Student") {
                        memberForMemberDetails.memberID = personDetails['register_id'];
                      }
                      prevPersonDetails = Map.from(personDetails);
                    }

                    return Column(children: [
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
                            child: Text(
                              "${memberForMemberDetails.building} / ${memberForMemberDetails.floor} / ${memberForMemberDetails.room}",
                              style: const TextStyle(backgroundColor: Colors.white),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      MapDetailsDisplayWidget(key: _mapDetailsDisplayWidget),
                      MemberDetails(
                          member: this.memberForMemberDetails, personDetails: personDetails)
                    ]);
                  },
                ),
              ],
            )));
  }
}

class MemberDetails extends StatelessWidget {
  final Member member;
  final Map<String, dynamic> personDetails;

  const MemberDetails({super.key, required this.member, required this.personDetails});

  List<Widget> buildDetails() {
    List<Widget> detailsList = <Widget>[];

    Map<bool, String> presenceConversion = {false: "User exited ", true: "User entered "};

    detailsList.add(DetailsTile("Name : ${member.name}"));
    detailsList.add(DetailsTile(presenceConversion[member.inRoom]! +
        CampusFindTime.getDifferenceFromNowTimestamp(member.lastLocationEntry)));

    detailsList.add(DetailsTile("Role: ${member.role}"));
    detailsList.add(DetailsTile("Member ID: ${member.memberID}"));
    detailsList.add(DetailsTile("In Room : ${member.inRoom}"));
    detailsList.add(DetailsTile("Status: ${member.status}"));

    return detailsList;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey, width: 1),
        ),
        width: 500,
        height: 210,
        child: ListView(padding: EdgeInsets.zero, children: buildDetails()));
  }
}

class CampusFindTime {
  static String getDifferenceFromNowTimestamp(Timestamp timestamp) {
    Duration timeDifference = DateTime.now().difference(timestamp.toDate());
    int totalTimeInSeconds = timeDifference.inSeconds;

    int h = totalTimeInSeconds ~/ 3600;

    int m = timeDifference.inMinutes - h * 60;

    int s = timeDifference.inSeconds - (m * 60 + h * 3600);

    if (h == 0 && m == 0) {
      return "$s sec ago";
    }

    if (h == 0) {
      return "$m min $s sec ago";
    }

    return "$h hours $m min $s sec ago";
  }
}
