// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'drop_down_box.dart';
import 'draw_map_text.dart';
import 'custom_datatypes/member.dart';
import 'members_search_bar.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late String name;
  Map<String, dynamic>? jsonData;

  late String selectedInputType;

  late bool doDisplayMemberDetails;
  late bool doDisplayMember;
  late Member memberForMemberDetails;
  late int appUserInstitutionID;

  final GlobalKey<MapDetailsDisplayWidgetState> _mapDetailsDisplayWidget = GlobalKey<MapDetailsDisplayWidgetState>();
  final GlobalKey<MemberSearchBarState> _memberSearchBar = GlobalKey<MemberSearchBarState>();

  @override
  initState()
  {
    super.initState();
    name = "Default";
    selectedInputType = "Person";
    memberForMemberDetails = Member("Default","SRMIST/GroundFloor/Room1",0,0);
    doDisplayMemberDetails = false;
    appUserInstitutionID = 1;
  }


  final List<DropdownMenuItem<String>> valuesInputType = [
    const DropdownMenuItem(value: 'Person', child: Text("Person")),
    const DropdownMenuItem(value: 'Room',child: Text("Room")),
    const DropdownMenuItem(value: 'Designation', child: Text("Designation")),
  ];

  void displayMemberNew(String memberName) async{
    setState(() {
      name = memberName;
    } 
    );
    await loadMemberDetails();
    _mapDetailsDisplayWidget.currentState?.refreshName(name);
  }


  void displayMemberDetails(String memberName)
  {
    setState(() {
      name = memberName;
    });
    loadMemberDetails();
  }

  Future<void> loadMemberDetails() async {

    String jsonString = await rootBundle.loadString('assets/members.json');
    setState(() {
      jsonData = json.decode(jsonString);

      var member = jsonData?["institution_members"]?.firstWhere(
        (member) => member['name'] == name && member['institution_id'] == appUserInstitutionID,
        orElse: () => null,
      );

      if (member != null) {
        doDisplayMemberDetails = true;
        memberForMemberDetails.name = member['name'];
        memberForMemberDetails.id = member['id'];
        memberForMemberDetails.changeManualLocation(member['manual_location']);
        memberForMemberDetails.institutionID = appUserInstitutionID;
      } else {
        doDisplayMemberDetails = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MemberSearchBar(_memberSearchBar, displayMemberNew, displayMemberDetails),
      //AppBar(
      //  title: const Text("Search Page"),
      //  backgroundColor: Colors.blue,
      //   foregroundColor: Colors.white,
      //),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: <Widget>[
            Column(children: [
              Row(children: [
            SizedBox(width: 10),
            Text(memberForMemberDetails.building + " / " + memberForMemberDetails.floor),
            const Spacer(),
            CustomDropdownButton(value: selectedInputType, items: valuesInputType, onChanged: (String? newInputType) {
                setState(() {
                  if (newInputType != null) {
                    selectedInputType = newInputType;
                  }
                });
              },
            ),
            ],
            )
            ]),
            //if(doDisplayMemberDetails) MemberDetails(this.memberForMemberDetails),
            MapDetailsDisplayWidget(key: _mapDetailsDisplayWidget),
            //MapDisplayWidget()
            Spacer
            (

            ),
            MemberDetails(this.memberForMemberDetails)
          ],
        ),
      ),
    );
  }
}

class MemberDetails extends StatelessWidget {
  final Member member;

  const MemberDetails(this.member, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 100,
      child: Column(
        children: [
          Text("ID: " + member.id.toString()),
          Text("Name: " + member.name),
        ],
      ),
    );
  }
}
