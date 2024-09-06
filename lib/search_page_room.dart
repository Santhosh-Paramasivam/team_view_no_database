import 'package:flutter/material.dart';
import 'drop_down_box.dart';
import 'draw_map_text.dart';

class RoomSearchPage extends StatefulWidget {
  const RoomSearchPage({super.key});

  @override
  State<RoomSearchPage> createState() => _RoomSearchPageState();
}

class _RoomSearchPageState extends State<RoomSearchPage> {
  final List<DropdownMenuItem<String>> valuesBuilding = [
    const DropdownMenuItem(value: 'Building1', child: Text("Building1")),
  ];

  final List<DropdownMenuItem<String>> valuesFloor = [
    const DropdownMenuItem(value: 'GroundFloor', child: Text("GroundFloor")),
    const DropdownMenuItem(value: 'FirstFloor', child: Text("FirstFloor")),
    const DropdownMenuItem(value: 'SecondFloor', child: Text("SecondFloor"))
  ];

  String selectedBuilding = "Building1";
  String selectedFloor = "GroundFloor";

  final GlobalKey<MapDetailsDisplayWidgetState> _mapDetailsDisplayWidget = GlobalKey<MapDetailsDisplayWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Venue Details"),
      ),
      body: Column(
        children: [
          // Wrapping Row inside a Container with width constraints
          Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Ensure Row shrinks to fit
              children: [
                CustomDropdownButton(value: selectedBuilding, items: valuesBuilding, onChanged: (String? chosenBuilding) {
                setState(() {
                  if (chosenBuilding != null) {
                    selectedBuilding = chosenBuilding;
                  }
                });
              },
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            ),
                CustomDropdownButton(value: selectedFloor, items: valuesFloor, onChanged: (String? newFloor) {
                setState(() {
                  if (newFloor != null) {
                    selectedFloor = selectedBuilding;
                  }
                });
              },
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            ),
              const Spacer(),
              ],
            ),
          ),
          MapDetailsDisplayWidget(key: _mapDetailsDisplayWidget),
        ],
      ),
    );
  }
}
