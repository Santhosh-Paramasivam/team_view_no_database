import 'package:flutter/material.dart';

class DetailsTile extends ListTile {
  DetailsTile(String title, {super.key})
      : super(
            title: Text(
              title,
              style: const TextStyle(fontSize: 15, height: 0),
            ),
            minTileHeight: 0);
}