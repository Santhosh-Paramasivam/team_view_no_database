import 'package:flutter/material.dart';

class StatusAndVisibility extends StatefulWidget {
  const StatusAndVisibility({super.key});

  @override
  State<StatusAndVisibility> createState() => _StatusAndVisibilityState();
}

class _StatusAndVisibilityState extends State<StatusAndVisibility> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Status And Visibility", style: TextStyle(color: Colors.white),),
      backgroundColor: Colors.blue), 
      body: const Column(children: 
      [
        SizedBox(height: 15),
        Row(
          children: 
          [
            SizedBox(width: 20,),
            Text("Status",
            style: TextStyle
            (
              color: Colors.blue,
              fontSize: 25,
              //fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.left,),
          ],)
      ],)
    );
  }
}