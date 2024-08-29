// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'drop_down_box.dart';
import 'draw_map_text.dart';
import 'draw_map.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String name = "";
  Map<String, dynamic>? jsonData;
  int id = 0;
  String username = "";
  String selectedInputType = "Person";
  String selectedBuilding = "Building1";
  String selectedFloor = "GroundFloor";

  final List<DropdownMenuItem<String>> valuesInputType = [
    const DropdownMenuItem(value: 'Person', child: Text("Person")),
    const DropdownMenuItem(value: 'Room',child: Text("Room")),
    const DropdownMenuItem(value: 'Designation', child: Text("Designation")),
  ];

  final List<DropdownMenuItem<String>> valuesBuilding = [
    const DropdownMenuItem(value: 'Building1', child: Text("Building1")),
  ];

  final List<DropdownMenuItem<String>> valuesFloor = [
    const DropdownMenuItem(value: 'GroundFloor', child: Text("GroundFloor")),
  ];

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<MapDetailsDisplayWidgetState> _mapDetailsDisplayWidget = GlobalKey<MapDetailsDisplayWidgetState>();

  Future<void> loadMemberDetails() async {
    String jsonString = await rootBundle.loadString('assets/members.json');
    setState(() {
      jsonData = json.decode(jsonString);

      var member = jsonData?["institution_members"]?.firstWhere(
        (member) => member['name'] == name,
        orElse: () => null,
      );

      if (member != null) {
        username = member['username'];
        id = member['id'];
        name = member['name'];
      } else {
        username = "";
        id = 0;
        name = "";
      }
    });
  }

  void displayMember() {
    setState(() {
      name = _searchController.text;
    });
    loadMemberDetails();
    _mapDetailsDisplayWidget.currentState?.refresh(name);
    print(name);
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
                        labelText: 'Search ' + selectedInputType,
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
                CustomDropdownButton(value: "Building1", items: valuesBuilding, onChanged: (String? newBuilding) {
                setState(() {
                  if (newBuilding != null) {
                    selectedBuilding = newBuilding;
                  }
                });
              },
            ),
                CustomDropdownButton(value: "GroundFloor", items: valuesFloor, onChanged: (String? newFloor) {
                setState(() {
                  if (newFloor != null) {
                    selectedFloor = newFloor;
                  }
                });
              },
            ),
            Spacer(),
            CustomDropdownButton(value: "Person", items: valuesInputType, onChanged: (String? newInputType) {
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
            //MemberDetails(username, id, name),
            //MapDetailsDisplayWidget(key: _mapDetailsDisplayWidget)
            MapDisplayWidget()
          ],
        ),
      ),
    );
  }
}

class MemberDetails extends StatelessWidget {
  final String name;
  final int id;
  final String username;

  MemberDetails(this.username, this.id, this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 100,
      child: Column(
        children: [
          Text("ID: $id"),
          Text("Name: $name"),
          Text("Username: $username"),
        ],
      ),
    );
  }
}
