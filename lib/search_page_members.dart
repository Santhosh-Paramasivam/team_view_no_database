// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'drop_down_box.dart';
import 'draw_map_text.dart';
import 'custom_datatypes/member.dart';


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

  @override
  initState()
  {
    super.initState();
    name = "Default";
    selectedInputType = "Person";
    //memberForMemberDetails = Member("Default","Building1/GroundFloor/Room1",0,0);
    memberForMemberDetails = Member("Default","Default",0,0);
    doDisplayMemberDetails = false;
  }


  final List<DropdownMenuItem<String>> valuesInputType = [
    const DropdownMenuItem(value: 'Person', child: Text("Person")),
    const DropdownMenuItem(value: 'Room',child: Text("Room")),
    const DropdownMenuItem(value: 'Designation', child: Text("Designation")),
  ];

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<MapDetailsDisplayWidgetState> _mapDetailsDisplayWidget = GlobalKey<MapDetailsDisplayWidgetState>();

  void displayMember() async{
    setState(() {
      name = _searchController.text;
    });
    await loadMemberDetails();
    _mapDetailsDisplayWidget.currentState?.refreshName(name);
  }

  void displayMemberDetails()
  {
    setState(() {
      name = _searchController.text;
    });
    loadMemberDetails();
  }

  Future<void> loadMemberDetails() async {

    String jsonString = await rootBundle.loadString('assets/members.json');
    setState(() {
      jsonData = json.decode(jsonString);

      var member = jsonData?["institution_members"]?.firstWhere(
        (member) => member['name'] == name,
        orElse: () => null,
      );

      if (member != null) {
        doDisplayMemberDetails = true;
        memberForMemberDetails.name = member['name'];
        memberForMemberDetails.id = member['id'];
        memberForMemberDetails.manualLocation = member['manual_location'];
      } else {
        doDisplayMemberDetails = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Page"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: <Widget>[
            Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person),
                        labelText: 'Search $selectedInputType',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.zero),
                        ),
                        suffixIcon: IconButton(
                          onPressed: displayMember,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(children: [
            //SizedBox(width: 10),
            //Text(memberForMemberDetails.building + " / " + memberForMemberDetails.floor),
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
