import 'package:flutter/material.dart';
import 'dropdown_widget.dart';
import 'set_location_map.dart';
import 'session_data/building_details.dart';

import 'drawer.dart';

class LocationSetPage extends StatefulWidget {
  const LocationSetPage({super.key});

  @override
  State<LocationSetPage> createState() => _LocationSetPageState();
}

class _LocationSetPageState extends State<LocationSetPage> {
  String selectedBuilding = BuildingDetails.buildings[0];
  String selectedFloor = BuildingDetails.floors[0];

  List<DropdownMenuItem<String>> createBuildingOptions() {
    List<DropdownMenuItem<String>> buildingOptions = [];

    for (String building in BuildingDetails.buildings) {
      buildingOptions.add(DropdownMenuItem(value: building, child: Text(building)));
    }

    return buildingOptions;
  }

  List<DropdownMenuItem<String>> createFloorOptions() {
    List<DropdownMenuItem<String>> floorOptions = [];

    for (String floor in BuildingDetails.floors) {
      floorOptions.add(DropdownMenuItem(value: floor, child: Text(floor)));
    }

    return floorOptions;
  }

  final GlobalKey<SetLocationMapWidgetState> _mapDetailsDisplayWidget =
      GlobalKey<SetLocationMapWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Venue Details"),
      ),
      drawer: CampusFindDrawer(),
      body: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 10,
              ),
              CustomDropdownButton(
                value: selectedBuilding,
                items: createBuildingOptions(),
                onChanged: (String? building) {
                  setState(() {
                    if (building != null) {
                      selectedBuilding = building;
                      _mapDetailsDisplayWidget.currentState!
                          .changeFloorAndBuilding(selectedFloor, selectedBuilding);
                    }
                  });
                },
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
              ),
              CustomDropdownButton(
                value: selectedFloor,
                items: createFloorOptions(),
                onChanged: (String? floor) {
                  setState(() {
                    if (floor != null) {
                      selectedFloor = floor;
                      _mapDetailsDisplayWidget.currentState!
                          .changeFloorAndBuilding(selectedFloor, selectedBuilding);
                    }
                  });
                },
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
              ),
              const Spacer(),
            ],
          ),
          const Divider(height: 1),
          SetLocationMap(key: _mapDetailsDisplayWidget),
        ],
      ),
    );
  }
}
