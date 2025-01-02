import 'package:flutter/material.dart';
import 'display_location_map.dart';
import 'search_members_bar.dart';
import 'firebase_connections/singleton_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'session_data/session_details.dart';

import 'drawer.dart';

import 'package:logger/logger.dart';
import 'custom_logger.dart';

class Member {
  String name;
  String rfidLocation;
  String institutionID;
  String id;
  late String floor;
  late String building;
  late String room;
  String role;
  String memberID;
  String status;

  Member(this.name, this.rfidLocation, this.institutionID, this.id, this.role, this.memberID,
      this.status) {
    List<String> rfidLocationList = rfidLocation.split("/");
    building = rfidLocationList[0];
    floor = rfidLocationList[1];
    room = rfidLocationList[2];
  }

  void changeRFIDLocation(String newRFIDLocation) {
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

  late String selectedInputType;

  late bool doDisplayMemberDetails;
  late bool doDisplayMember;

  late Member memberForMemberDetails;
  late String appUserInstitutionID;

  final GlobalKey<MapDetailsDisplayWidgetState> _mapDetailsDisplayWidget =
      GlobalKey<MapDetailsDisplayWidgetState>();
  final GlobalKey<MemberSearchBarState> _memberSearchBar = GlobalKey<MemberSearchBarState>();

  Map<String, dynamic> prevPersonDetails = Map<String, dynamic>();

  @override
  initState() {
    super.initState();
    selectedInputType = "Person";
    memberForMemberDetails = Member("Default", "SRMIST/GroundFloor/Room1", "", "", "Default Role",
        "Default ID", "Default Status");
    doDisplayMemberDetails = true;
    appUserInstitutionID = SessionDetails.institution_id;
    //name = "Santhosh Paramasivam";
    displayMemberNew(SessionDetails.name);
    displayMemberDetails(SessionDetails.name);
  }

  void displayMemberNew(String memberName) async {
    setState(() {
      name = memberName;
    });
    _mapDetailsDisplayWidget.currentState?.refreshName(name);
  }

  Stream<QuerySnapshot> fetchUsersStream() {
    return FirestoreService()
        .firestore
        .collection("institution_members")
        .where("name", isEqualTo: name)
        .where("institution_id", isEqualTo: appUserInstitutionID)
        .limit(1)
        .snapshots();
  }

  void displayMemberDetails(String memberName) {
    setState(() {
      name = memberName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: MemberSearchBar(_memberSearchBar, displayMemberNew, displayMemberDetails),
        drawer: CampusFindDrawer(),
        body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: fetchUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Container(
                          width: double.infinity,
                          height: 100,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: Text("Error fetching data"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                          width: double.infinity,
                          height: 100,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: Center(child: CircularProgressIndicator()));
                    }

                    var doc = snapshot.data!.docs.first;
                    Map<String, dynamic> personDetails = doc.data() as Map<String, dynamic>;

                    final eq = const DeepCollectionEquality().equals;

                    if (!eq(personDetails, prevPersonDetails)) {
                      print("Auto-update data reached");

                      doDisplayMemberDetails = true;
                      memberForMemberDetails.name = personDetails['name'];
                      memberForMemberDetails.id = personDetails['id'];
                      memberForMemberDetails.changeRFIDLocation(personDetails['rfid_location']);
                      memberForMemberDetails.institutionID = appUserInstitutionID;
                      memberForMemberDetails.role = personDetails['user_role'];
                      memberForMemberDetails.status = personDetails['status'];

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
                              style: TextStyle(backgroundColor: Colors.white),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      MapDetailsDisplayWidget(key: _mapDetailsDisplayWidget),
                      const SizedBox(
                        height: 15,
                      ),
                      //MemberDetails(this.memberForMemberDetails),
                      MemberDetails(member: this.memberForMemberDetails)
                    ]);
                  },
                ),
              ],
            )));
  }
}

class MemberDetails extends StatelessWidget {
  final Member member;

  const MemberDetails({super.key, required this.member});

  List<Widget> buildDetails() {
    List<Widget> detailsList = <Widget>[];

    detailsList.add(DetailsTile("Name : ${member.name}"));
    detailsList.add(DetailsTile("Role: ${member.role}"));
    detailsList.add(DetailsTile("Faculty ID: ${member.memberID}"));
    //detailsList.add(DetailsTile("Register Number: ${member.memberID}"));
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
        height: 200,
        child: ListView(padding: EdgeInsets.zero, children: buildDetails()));
  }
}

class DetailsTile extends ListTile {
  DetailsTile(String title, {super.key})
      : super(
            title: Text(
              title,
              style: const TextStyle(fontSize: 15, height: 0),
            ),
            minTileHeight: 0);
}
