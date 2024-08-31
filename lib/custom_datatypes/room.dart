import 'dart:convert';
import 'package:flutter/services.dart';

class Room {
  List<Offset> roomVertices;
  String roomName;

  Room(this.roomVertices, this.roomName);
}
