import 'package:flutter/material.dart';

class IconDropdownPage extends StatefulWidget {
  const IconDropdownPage({super.key});

  @override
  _IconDropdownPageState createState() => _IconDropdownPageState();
}

class _IconDropdownPageState extends State<IconDropdownPage> {
  String? selectedValue;

  final List<DropdownMenuItem<String>> _dropdownItems = [
    DropdownMenuItem(
      value: 'Person',
      child: Row(
        children: const [
          Icon(Icons.person),
          SizedBox(width: 10),
          Text("Person"),
        ],
      ),
    ),
    DropdownMenuItem(
      value: 'Home',
      child: Row(
        children: const [
          Icon(Icons.home),
          SizedBox(width: 10),
          Text("Home"),
        ],
      ),
    ),
    DropdownMenuItem(
      value: 'Settings',
      child: Row(
        children: const [
          Icon(Icons.settings),
          SizedBox(width: 10),
          Text("Settings"),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dropdown with Icons")),
      body: Center(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: const Text("Select an option"),
          items: _dropdownItems,
          onChanged: (String? newValue) {
            setState(() {
              selectedValue = newValue;
            });
          },
        ),
      ),
    );
  }
}