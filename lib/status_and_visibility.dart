import 'package:flutter/material.dart';
import 'drop_down_box.dart';
import 'dart:convert';
import 'dart:io';

class StatusAndVisibility extends StatefulWidget {
  const StatusAndVisibility({super.key});

  @override
  State<StatusAndVisibility> createState() => _StatusAndVisibilityState();
}

class _StatusAndVisibilityState extends State<StatusAndVisibility> {
  late String selectedInputType;
  late List<DropdownMenuItem<String>> valuesInputType;
  late Map<String,dynamic> jsonData;
  TextEditingController addStatusController = TextEditingController();

  @override
  initState()
  {
    super.initState();
    selectedInputType = "Available";
    valuesInputType = [];
    loadStatusOptions();
  }

  Future<void> loadStatusOptions() async {

    //String jsonString = await rootBundle.loadString('assets/status.json');
    final file_ = File('assets/status.json');
    String jsonString = await file_.readAsString();
    
    setState(() {
      jsonData = json.decode(jsonString);

      var status = jsonData["statuses"]?.firstWhere(
        (status) => status["status_id"] == 1,
        orElse: () => null,
      );

      print(status['status_values']);

      valuesInputType.clear();
      for(String eachStatus in status['status_values'])
      {
        valuesInputType.add(DropdownMenuItem(value: eachStatus, child: Text(eachStatus)));
      }
    });
  }
  Future<void> updateStatusOptions(String newStatus) async {

    if(newStatus == "") return;

    final file = File('assets/status.json');
    String updatedJsonString = "";
    String jsonString = await file.readAsString();

    setState(() {
      jsonData = json.decode(jsonString);
      jsonData['statuses'][0]['status_values'].add(newStatus);
      updatedJsonString = json.encode(jsonData);
     
    });
    await file.writeAsString(updatedJsonString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Status And Visibility", style: TextStyle(color: Colors.white),),
      backgroundColor: Colors.blue), 
      body: Column(children: 
      [
        const SizedBox(height: 15),
        Row(
          children: 
          [
            //SizedBox(width: 100),
          const SizedBox
            (
              width: 200,
              height: 30,
              child: Text("Status",
                style: TextStyle
                (
                  color: Colors.black,
                  fontSize: 20,
                  //fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,),
            ),
            const Spacer(),
             SizedBox
             (
              height: 40,
              width: 400,
              child: CustomDropdownButton(value: selectedInputType, items: valuesInputType, onChanged: (String? newInputType) {
                setState(() {
                  if (newInputType != null) {
                    selectedInputType = newInputType;
                  }
                });
              },
              padding: const EdgeInsets.fromLTRB(100, 5, 100, 10),
            ),
             ),
            const SizedBox(width: 20)
          ],),
          const SizedBox(height: 20),
          Row(children: [
            const SizedBox(width: 25),
             const SizedBox
            (
              width: 200,
              height: 30,
              child: Text("Add Status",
                style: TextStyle
                (
                  color: Colors.black,
                  fontSize: 20,
                  //fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,),
            ),
            const Spacer(),
            SizedBox(
              width: 400,
              height: 40,
              child: TextField(
              controller: addStatusController,
              decoration: InputDecoration(
              labelText: 'New Status',
              border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.zero),
                ),
              suffixIcon: IconButton(
              onPressed: () async {
                await updateStatusOptions(addStatusController.text);
              setState((){
              loadStatusOptions();
              });},
              icon: const Icon(Icons.add)),)),
            ),
            const SizedBox(width: 20)
      ]),
      ],)
    );
  }
}