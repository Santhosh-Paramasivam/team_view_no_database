import 'package:flutter/material.dart';
import 'login.dart';
import 'drawPoints1.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp
    (
        title: "TeamView",
        theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
        home: PointsDisplayPage(),
    );
  }
}